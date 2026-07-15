import 'dart:async';

import 'package:dartz/dartz.dart' show Either;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_apply_ai/core/enums/view_state.dart';
import 'package:flutter_apply_ai/core/errors/failures.dart';
import 'package:flutter_apply_ai/core/utils/app_logger.dart';
import 'package:flutter_apply_ai/core/utils/input_validators.dart';
import 'package:flutter_apply_ai/domain/entities/app_settings.dart';
import 'package:flutter_apply_ai/domain/entities/enums/app_theme_mode.dart';
import 'package:flutter_apply_ai/domain/entities/resume_profile.dart';
import 'package:flutter_apply_ai/domain/usecases/gmail/connect_gmail_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/gmail/disconnect_gmail_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/gmail/is_gmail_connected_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/resume/add_resume_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/resume/delete_resume_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/resume/get_resumes_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/resume/set_default_resume_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/settings/get_settings_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/settings/save_gemini_api_key_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/settings/update_settings_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/usecase.dart';
import 'package:flutter_apply_ai/presentation/shared/controllers/theme_controller.dart';
import 'package:flutter_apply_ai/presentation/shared/theme_mode_x.dart';
import 'package:get/get.dart';

/// ViewModel for the Settings screen: Gemini API key, resume management, Gmail
/// connection, and appearance (theme).
class SettingsController extends GetxController {
  SettingsController({
    required GetSettingsUseCase getSettings,
    required SaveGeminiApiKeyUseCase saveGeminiApiKey,
    required UpdateSettingsUseCase updateSettings,
    required GetResumesUseCase getResumes,
    required AddResumeUseCase addResume,
    required DeleteResumeUseCase deleteResume,
    required SetDefaultResumeUseCase setDefaultResume,
    required ConnectGmailUseCase connectGmail,
    required DisconnectGmailUseCase disconnectGmail,
    required IsGmailConnectedUseCase isGmailConnected,
    required ThemeController themeController,
    required AppLogger logger,
  })  : _getSettings = getSettings,
        _saveGeminiApiKey = saveGeminiApiKey,
        _updateSettings = updateSettings,
        _getResumes = getResumes,
        _addResume = addResume,
        _deleteResume = deleteResume,
        _setDefaultResume = setDefaultResume,
        _connectGmail = connectGmail,
        _disconnectGmail = disconnectGmail,
        _isGmailConnected = isGmailConnected,
        _themeController = themeController,
        _logger = logger;

  final GetSettingsUseCase _getSettings;
  final SaveGeminiApiKeyUseCase _saveGeminiApiKey;
  final UpdateSettingsUseCase _updateSettings;
  final GetResumesUseCase _getResumes;
  final AddResumeUseCase _addResume;
  final DeleteResumeUseCase _deleteResume;
  final SetDefaultResumeUseCase _setDefaultResume;
  final ConnectGmailUseCase _connectGmail;
  final DisconnectGmailUseCase _disconnectGmail;
  final IsGmailConnectedUseCase _isGmailConnected;
  final ThemeController _themeController;
  final AppLogger _logger;

  final TextEditingController apiKeyController = TextEditingController();
  final TextEditingController senderNameController = TextEditingController();
  final TextEditingController profileController = TextEditingController();

  final Rx<ViewState> loadState = ViewState.initial.obs;
  final Rx<AppSettings> settings = AppSettings.empty.obs;
  final RxList<ResumeProfile> resumes = <ResumeProfile>[].obs;

  final RxBool obscureApiKey = true.obs;
  final RxBool savingApiKey = false.obs;
  final RxBool connectingGmail = false.obs;

  AppThemeMode get themeMode => settings.value.themeMode;
  bool get isGmailConnected => settings.value.isGmailConnected;
  String get gmailAccount => settings.value.gmailAccountEmail ?? '';

  @override
  void onInit() {
    super.onInit();
    unawaited(loadAll());
  }

  Future<void> loadAll() async {
    loadState.value = ViewState.loading;
    final settingsResult = await _getSettings(const NoParams());
    settingsResult.fold(
      (failure) {
        _logger.w('Failed to load settings: ${failure.message}');
        loadState.value = ViewState.error;
      },
      (AppSettings loaded) {
        settings.value = loaded;
        apiKeyController.text = loaded.geminiApiKey;
        senderNameController.text = loaded.senderName;
        profileController.text = loaded.profileSummary;
      },
    );

    final resumesResult = await _getResumes(const NoParams());
    resumesResult.fold(
      (_) {},
      resumes.assignAll,
    );

    await _reconcileGmailState();

    if (!loadState.value.isError) {
      loadState.value = ViewState.success;
    }
  }

  /// Reconciles the persisted "connected" label with the real token state: if
  /// the settings claim a connected account but no token exists (e.g. tokens
  /// were revoked or cleared), clears the stale label so the UI is truthful.
  Future<void> _reconcileGmailState() async {
    if (!settings.value.isGmailConnected) {
      return;
    }
    final result = await _isGmailConnected(const NoParams());
    final bool hasTokens = result.getOrElse(() => false);
    if (!hasTokens) {
      _logger.w('Gmail label present but no token — reconciling to disconnected.');
      await _disconnectGmail(const NoParams());
      await _reloadSettings();
    }
  }

  void toggleApiKeyVisibility() => obscureApiKey.toggle();

  Future<void> saveApiKey() async {
    final String key = apiKeyController.text.trim();
    final String? error = InputValidators.geminiApiKey(key);
    if (error != null) {
      _notify('Invalid API key', error);
      return;
    }

    savingApiKey.value = true;
    final result = await _saveGeminiApiKey(key);
    savingApiKey.value = false;

    if (result.isRight()) {
      settings.value = settings.value.copyWith(geminiApiKey: key);
      _notify('Saved', 'OpenAI API key saved securely.');
    } else {
      _notify('Error', _messageOf(result));
    }
  }

  Future<void> saveProfile() async {
    final AppSettings updated = settings.value.copyWith(
      senderName: senderNameController.text.trim(),
      profileSummary: profileController.text.trim(),
    );
    final result = await _updateSettings(updated);
    if (result.isRight()) {
      settings.value = updated;
      _notify('Saved', 'Your profile was updated.');
    } else {
      _notify('Error', _messageOf(result));
    }
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    _themeController.setMode(mode.toThemeMode);
    final AppSettings updated = settings.value.copyWith(themeMode: mode);
    settings.value = updated;
    final result = await _updateSettings(updated);
    if (result.isLeft()) {
      _notify('Error', _messageOf(result));
    }
  }

  /// Opens the OS file picker and returns the chosen resume path (or `null`).
  Future<String?> pickResumeFile() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['pdf', 'doc', 'docx', 'rtf', 'txt'],
      dialogTitle: 'Choose a resume file',
    );
    return result?.files.single.path;
  }

  Future<void> addResume({
    required String label,
    required String filePath,
    bool makeDefault = false,
  }) async {
    if (label.trim().isEmpty || filePath.trim().isEmpty) {
      _notify('Missing details', 'Provide a label and choose a file.');
      return;
    }
    final result = await _addResume(
      AddResumeParams(
        label: label.trim(),
        filePath: filePath,
        makeDefault: makeDefault,
      ),
    );
    if (result.isRight()) {
      await _reloadResumes();
      _notify('Resume added', '"$label" is now available.');
    } else {
      _notify('Error', _messageOf(result));
    }
  }

  Future<void> deleteResume(String id) async {
    final result = await _deleteResume(id);
    if (result.isRight()) {
      await _reloadResumes();
    } else {
      _notify('Error', _messageOf(result));
    }
  }

  Future<void> setDefaultResume(String id) async {
    final result = await _setDefaultResume(id);
    if (result.isRight()) {
      await _reloadResumes();
    } else {
      _notify('Error', _messageOf(result));
    }
  }

  Future<void> connectGmail() async {
    if (connectingGmail.value) {
      return;
    }
    connectingGmail.value = true;
    final result = await _connectGmail(const NoParams());
    connectingGmail.value = false;

    if (result.isRight()) {
      await _reloadSettings();
      _notify('Gmail connected', 'Signed in as $gmailAccount.');
    } else {
      _notify('Gmail', _messageOf(result));
    }
  }

  Future<void> disconnectGmail() async {
    final result = await _disconnectGmail(const NoParams());
    if (result.isRight()) {
      await _reloadSettings();
      _notify('Gmail disconnected', 'Your Gmail session was removed.');
    } else {
      _notify('Error', _messageOf(result));
    }
  }

  Future<void> _reloadSettings() async {
    final result = await _getSettings(const NoParams());
    result.fold((_) {}, (AppSettings loaded) => settings.value = loaded);
  }

  Future<void> _reloadResumes() async {
    final result = await _getResumes(const NoParams());
    result.fold(
      (_) {},
      resumes.assignAll,
    );
  }

  String _messageOf<T>(Either<Failure, T> result) {
    return result.fold(
      (Failure failure) => failure.message,
      (_) => 'Unknown error.',
    );
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
    apiKeyController.dispose();
    senderNameController.dispose();
    profileController.dispose();
    super.onClose();
  }
}
