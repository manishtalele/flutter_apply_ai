import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_apply_ai/core/enums/view_state.dart';
import 'package:flutter_apply_ai/core/errors/failures.dart';
import 'package:flutter_apply_ai/core/utils/app_logger.dart';
import 'package:flutter_apply_ai/core/utils/signature_formatter.dart';
import 'package:flutter_apply_ai/domain/entities/app_settings.dart';
import 'package:flutter_apply_ai/domain/entities/application.dart';
import 'package:flutter_apply_ai/domain/entities/enums/candidate_detail.dart';
import 'package:flutter_apply_ai/domain/entities/job_posting.dart';
import 'package:flutter_apply_ai/domain/entities/resume_profile.dart';
import 'package:flutter_apply_ai/domain/usecases/ai/analyze_job_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/application/check_duplicate_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/application/send_application_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/resume/get_resumes_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/settings/get_settings_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/usecase.dart';
import 'package:flutter_apply_ai/presentation/history/controllers/history_controller.dart';
import 'package:flutter_apply_ai/presentation/shell/controllers/shell_controller.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

/// ViewModel for the Home screen: paste → AI analyze → preview → apply.
///
/// The Apply pipeline (Module 14): validate → check duplicates (with an
/// "apply again?" confirmation) → send via Gmail with the selected resume →
/// persist → refresh History.
class HomeController extends GetxController {
  HomeController({
    required AnalyzeJobUseCase analyzeJob,
    required CheckDuplicateUseCase checkDuplicate,
    required SendApplicationUseCase sendApplication,
    required GetResumesUseCase getResumes,
    required GetSettingsUseCase getSettings,
    required AppLogger logger,
  })  : _analyzeJob = analyzeJob,
        _checkDuplicate = checkDuplicate,
        _sendApplication = sendApplication,
        _getResumes = getResumes,
        _getSettings = getSettings,
        _logger = logger {
    // Attached here rather than in onInit so the draft mirrors stay in sync
    // even when the controller is constructed outside GetX's lifecycle.
    subjectController.addListener(_onDraftChanged);
    bodyController.addListener(_onDraftChanged);
  }

  final AnalyzeJobUseCase _analyzeJob;
  final CheckDuplicateUseCase _checkDuplicate;
  final SendApplicationUseCase _sendApplication;
  final GetResumesUseCase _getResumes;
  final GetSettingsUseCase _getSettings;
  final AppLogger _logger;

  final TextEditingController pasteController = TextEditingController();

  /// The editable draft. Seeded from the AI result on every analysis; whatever
  /// is in these fields at Apply time is what gets sent and saved to History.
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController bodyController = TextEditingController();

  /// Mirrors of the two controllers above, so `Obx` widgets (the Apply button's
  /// enabled state) react to typing — plain [TextEditingController]s are not
  /// observable by GetX.
  final RxString draftSubject = ''.obs;
  final RxString draftBody = ''.obs;

  /// Whether the user has changed the AI's subject or body.
  final RxBool isEdited = false.obs;

  final Rx<ViewState> state = ViewState.initial.obs;
  final Rxn<JobPosting> posting = Rxn<JobPosting>();
  final RxString errorMessage = ''.obs;

  final RxList<ResumeProfile> resumes = <ResumeProfile>[].obs;
  final Rxn<ResumeProfile> selectedResume = Rxn<ResumeProfile>();
  final RxList<String> extraAttachments = <String>[].obs;
  final Rx<AppSettings> settings = AppSettings.empty.obs;
  final RxBool applying = false.obs;

  static const int _settingsTabIndex = 3;
  Worker? _tabWorker;

  bool get hasResult => posting.value != null;

  /// The posting as it will actually be sent: the AI's extracted fields with
  /// the user's edited subject and body applied on top.
  JobPosting? get draftPosting => posting.value?.copyWith(
        subject: draftSubject.value.trim(),
        emailBody: draftBody.value.trim(),
      );

  bool get canApply => (draftPosting?.isSendable ?? false) && !applying.value;

  /// Details this post asks for that the user has not filled in under Settings.
  ///
  /// The AI is instructed to omit rather than invent an unknown detail, so
  /// these are silently missing from the subject and body — surfacing them is
  /// the only way the user finds out.
  List<CandidateDetail> get missingRequestedDetails {
    final JobPosting? current = posting.value;
    if (current == null) {
      return const <CandidateDetail>[];
    }
    final AppSettings saved = settings.value;
    return current.requestedDetails
        .where((CandidateDetail detail) => !saved.hasDetail(detail))
        .toList(growable: false);
  }

  bool get needsApiKey => !settings.value.hasOpenAiKey;
  bool get needsGmail => !settings.value.isGmailConnected;
  bool get needsResume => resumes.isEmpty;
  bool get needsSetup => needsApiKey || needsGmail || needsResume;

  /// Human-readable list of the setup steps still outstanding.
  List<String> get missingSetupItems => <String>[
        if (needsApiKey) 'OpenAI API key',
        if (needsGmail) 'Gmail connection',
        if (needsResume) 'a resume',
      ];

  @override
  void onInit() {
    super.onInit();
    unawaited(_loadContext());
    // Refresh setup/context state whenever the user returns to the Home tab
    // (e.g. after configuring the API key or connecting Gmail in Settings).
    if (Get.isRegistered<ShellController>()) {
      _tabWorker = ever<int>(
        Get.find<ShellController>().currentIndex,
        (int index) {
          if (index == 0) {
            unawaited(_loadContext());
          }
        },
      );
    }
  }

  /// Switches the shell to the Settings tab.
  void openSettings() {
    if (Get.isRegistered<ShellController>()) {
      Get.find<ShellController>().changeTo(_settingsTabIndex);
    }
  }

  Future<void> _loadContext() async {
    final settingsResult = await _getSettings(const NoParams());
    settingsResult.fold((_) {}, (AppSettings s) => settings.value = s);

    final resumesResult = await _getResumes(const NoParams());
    resumesResult.fold((_) {}, (List<ResumeProfile> list) {
      resumes.assignAll(list);
      selectedResume.value =
          list.firstWhereOrNull((ResumeProfile r) => r.isDefault) ??
              (list.isEmpty ? null : list.first);
    });
  }

  void selectResume(ResumeProfile? resume) => selectedResume.value = resume;

  /// The AI's untouched output, kept so [restoreAiDraft] can undo edits.
  String _aiSubject = '';
  String _aiBody = '';

  void _onDraftChanged() {
    draftSubject.value = subjectController.text;
    draftBody.value = bodyController.text;
    isEdited.value =
        subjectController.text != _aiSubject || bodyController.text != _aiBody;
  }

  /// Seeds the editable draft with a fresh AI result.
  void _seedDraft({required String subject, required String body}) {
    _aiSubject = subject;
    _aiBody = body;
    subjectController.text = subject;
    bodyController.text = body;
    // Set the mirrors explicitly rather than relying on the listener, so the
    // draft is correct even if a listener is ever detached.
    draftSubject.value = subject;
    draftBody.value = body;
    isEdited.value = false;
  }

  /// Discards the user's edits and restores the AI-generated subject and body.
  void restoreAiDraft() {
    if (!isEdited.value) {
      return;
    }
    _seedDraft(subject: _aiSubject, body: _aiBody);
  }

  /// Appends the user's saved signature (as HTML) to the AI-generated email
  /// body. No-op when the signature is empty.
  String _appendSignature(String body) {
    final String html = SignatureFormatter.toHtml(settings.value.emailSignature);
    if (html.isEmpty) {
      return body;
    }
    return '$body<br><br>$html';
  }

  /// Opens the file picker to attach one or more additional files (beyond the
  /// resume), de-duplicating by path.
  Future<void> addAttachments() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      dialogTitle: 'Attach files',
    );
    if (result == null) {
      return;
    }
    for (final PlatformFile file in result.files) {
      final String? path = file.path;
      if (path != null && !extraAttachments.contains(path)) {
        extraAttachments.add(path);
      }
    }
  }

  void removeAttachment(String path) => extraAttachments.remove(path);

  /// Opens WhatsApp on the post's phone number with a personalized message
  /// pre-filled. WhatsApp does not allow apps to auto-attach files, so the
  /// resume must be attached manually in the WhatsApp window before sending.
  Future<void> openWhatsApp() async {
    final JobPosting? current = posting.value;
    if (current == null) {
      return;
    }
    final String number = _normalizePhone(current.phone);
    if (number.isEmpty) {
      _notify('No number', 'No phone number was detected in this post.');
      return;
    }
    final String message = _whatsAppMessage(current);
    final Uri uri = Uri.parse(
      'https://wa.me/$number?text=${Uri.encodeComponent(message)}',
    );
    final bool launched =
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      _notify('Could not open', 'Unable to open WhatsApp for this number.');
    }
  }

  /// Reduces a raw phone string to digits and applies an India default country
  /// code when a bare 10-digit number is provided.
  String _normalizePhone(String raw) {
    final String digits =
        raw.split('').where((String c) => '0123456789'.contains(c)).join();
    if (digits.length == 10) {
      return '91$digits';
    }
    if (digits.length == 11 && digits.startsWith('0')) {
      return '91${digits.substring(1)}';
    }
    return digits;
  }

  String _whatsAppMessage(JobPosting posting) {
    final String name = settings.value.senderName.trim();
    final String role = posting.role.trim();
    final String company = posting.company.trim();
    final StringBuffer buffer = StringBuffer('Hi');
    if (company.isNotEmpty) {
      buffer.write(' $company team');
    }
    buffer.write(',\n\nI came across the ');
    buffer.write(role.isEmpty ? 'job opening' : '$role opening');
    buffer.write(" and I'm very interested in applying.");
    if (name.isNotEmpty) {
      buffer.write(' My name is $name.');
    }
    buffer.write(' I\'m sharing my resume here for your consideration.');
    return buffer.toString();
  }

  String get _candidateProfile {
    final String summary = settings.value.profileSummary.trim();
    if (summary.isNotEmpty) {
      return summary;
    }
    // Fallback when the user hasn't filled a profile summary yet.
    final List<String> parts = <String>[];
    if (settings.value.senderName.isNotEmpty) {
      parts.add('Applicant: ${settings.value.senderName}');
    }
    final ResumeProfile? resume = selectedResume.value;
    if (resume != null) {
      parts.add('Applying with resume profile: ${resume.label}');
    }
    return parts.join('. ');
  }

  Future<void> analyze() async {
    final String text = pasteController.text.trim();
    if (text.isEmpty) {
      _notify('Nothing to analyze', 'Paste a job description first.');
      return;
    }

    state.value = ViewState.loading;
    errorMessage.value = '';

    final result = await _analyzeJob(
      AnalyzeJobParams(
        rawText: text,
        candidateProfile: _candidateProfile,
        candidateDetails: settings.value.candidateDetails,
      ),
    );
    result.fold(
      (Failure failure) {
        _logger.w('Job analysis failed: ${failure.message}');
        errorMessage.value = failure.message;
        state.value = ViewState.error;
        _notify('Analysis failed', failure.message);
      },
      (JobPosting analyzed) {
        final JobPosting withSignature = analyzed.copyWith(
          emailBody: _appendSignature(analyzed.emailBody),
        );
        posting.value = withSignature;
        _seedDraft(
          subject: withSignature.subject,
          body: withSignature.emailBody,
        );
        state.value = ViewState.success;
        _logger.i('Job analyzed: ${analyzed.company} / ${analyzed.role}');
      },
    );
  }

  void clear() {
    pasteController.clear();
    posting.value = null;
    errorMessage.value = '';
    extraAttachments.clear();
    _seedDraft(subject: '', body: '');
    state.value = ViewState.initial;
  }

  Future<void> copyEmail() async {
    final JobPosting? current = draftPosting;
    if (current == null) {
      return;
    }
    await Clipboard.setData(
      ClipboardData(text: 'Subject: ${current.subject}\n\n${current.emailBody}'),
    );
    _notify('Copied', 'Subject and email body copied to clipboard.');
  }

  Future<void> apply() async {
    // The edited draft — not the raw AI output — is what gets sent.
    final JobPosting? current = draftPosting;
    if (current == null || applying.value) {
      return;
    }
    if (!current.isSendable) {
      _notify(
        'Cannot apply',
        'This posting is missing a recipient email, subject, or body.',
      );
      return;
    }
    if (!settings.value.isGmailConnected) {
      _notify('Gmail not connected', 'Connect your Gmail in Settings first.');
      return;
    }
    final ResumeProfile? resume = selectedResume.value;
    if (resume == null) {
      _notify('No resume', 'Add and select a resume in Settings.');
      return;
    }

    if (!await _passesDuplicateCheck(current.email)) {
      return;
    }

    applying.value = true;
    final result = await _sendApplication(
      SendApplicationParams(
        posting: current,
        resume: resume,
        senderName: settings.value.senderName,
        extraAttachmentPaths: List<String>.of(extraAttachments),
        appliedAt: DateTime.now(),
      ),
    );
    applying.value = false;

    result.fold(
      (Failure failure) {
        _logger.w('Send application failed: ${failure.message}');
        _notify('Failed to send', failure.message);
      },
      (Application saved) {
        _logger.i('Applied to ${saved.company} (${saved.email}).');
        _notify('Application sent', 'Applied to ${saved.company}.');
        _refreshHistory();
        clear();
      },
    );
  }

  /// Returns true if it is OK to proceed — either there is no prior application
  /// to this email, or the user confirmed applying again.
  Future<bool> _passesDuplicateCheck(String email) async {
    final result = await _checkDuplicate(email);
    final List<Application> existing =
        result.fold((_) => <Application>[], (List<Application> list) => list);
    if (existing.isEmpty) {
      return true;
    }
    return _confirmApplyAgain(existing.length);
  }

  Future<bool> _confirmApplyAgain(int count) async {
    final bool? confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Already applied'),
        content: Text(
          'You have already applied to this email address $count time(s). '
          'Apply again?',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Get.back<bool>(result: false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Get.back<bool>(result: true),
            child: const Text('Apply again'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  void _refreshHistory() {
    if (Get.isRegistered<HistoryController>()) {
      unawaited(Get.find<HistoryController>().reload());
    }
  }

  void _notify(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void onClose() {
    _tabWorker?.dispose();
    pasteController.dispose();
    subjectController
      ..removeListener(_onDraftChanged)
      ..dispose();
    bodyController
      ..removeListener(_onDraftChanged)
      ..dispose();
    super.onClose();
  }
}
