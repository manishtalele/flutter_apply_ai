import 'package:equatable/equatable.dart';
import 'package:flutter_apply_ai/domain/entities/enums/app_theme_mode.dart';
import 'package:flutter_apply_ai/domain/entities/enums/candidate_detail.dart';

/// User-configurable application settings.
///
/// [openAiApiKey] and Gmail credentials are secrets: the data layer persists
/// the key via secure storage and never in plain preferences. Non-secret
/// fields (theme, default resume, connected account label) go to
/// SharedPreferences.
class AppSettings extends Equatable {
  const AppSettings({
    this.openAiApiKey = '',
    this.defaultResumeId,
    this.themeMode = AppThemeMode.dark,
    this.gmailAccountEmail,
    this.senderName = '',
    this.profileSummary = '',
    this.emailSignature = '',
    this.currentLocation = '',
    this.totalExperience = '',
    this.currentCtc = '',
    this.expectedCtc = '',
    this.noticePeriod = '',
  });

  /// Empty/default settings for first launch.
  static const AppSettings empty = AppSettings();

  final String openAiApiKey;
  final String? defaultResumeId;
  final AppThemeMode themeMode;

  /// The connected Gmail account's address, or `null` when not connected.
  final String? gmailAccountEmail;

  /// Display name used as the email "From" name.
  final String senderName;

  /// Free-text summary of the candidate's skills/experience, fed to the AI to
  /// compute a meaningful match score.
  final String profileSummary;

  /// Multi-line signature block appended to every application email (name,
  /// role, phone, email, links). Stored as plain text; converted to HTML when
  /// appended to the outgoing email.
  final String emailSignature;

  /// Where the candidate is currently based, e.g. "Pune, India". Job posts
  /// frequently ask applicants to state this in the mail.
  final String currentLocation;

  /// Total professional experience, e.g. "3.5 years".
  final String totalExperience;

  /// Current annual compensation, e.g. "8 LPA".
  final String currentCtc;

  /// Expected annual compensation, e.g. "12 LPA".
  final String expectedCtc;

  /// Availability / notice period, e.g. "30 days" or "Immediate joiner".
  final String noticePeriod;

  /// The stored value for [detail], or `''` when the user has not filled it in.
  String detailValue(CandidateDetail detail) {
    switch (detail) {
      case CandidateDetail.currentLocation:
        return currentLocation;
      case CandidateDetail.totalExperience:
        return totalExperience;
      case CandidateDetail.currentCtc:
        return currentCtc;
      case CandidateDetail.expectedCtc:
        return expectedCtc;
      case CandidateDetail.noticePeriod:
        return noticePeriod;
    }
  }

  /// Whether the user has provided [detail].
  bool hasDetail(CandidateDetail detail) =>
      detailValue(detail).trim().isNotEmpty;

  /// The candidate facts a job post may explicitly ask for, as
  /// `label -> value` pairs. Blank fields are omitted so the AI is never told
  /// about a detail the user has not filled in (and so cannot invent one).
  Map<String, String> get candidateDetails {
    final Map<String, String> details = <String, String>{
      'Full name': senderName,
      for (final CandidateDetail detail in CandidateDetail.values)
        detail.label: detailValue(detail),
    };
    details.removeWhere((_, String value) => value.trim().isEmpty);
    return details;
  }

  bool get hasOpenAiKey => openAiApiKey.trim().isNotEmpty;

  bool get isGmailConnected =>
      gmailAccountEmail != null && gmailAccountEmail!.trim().isNotEmpty;

  AppSettings copyWith({
    String? openAiApiKey,
    String? defaultResumeId,
    AppThemeMode? themeMode,
    String? gmailAccountEmail,
    String? senderName,
    String? profileSummary,
    String? emailSignature,
    String? currentLocation,
    String? totalExperience,
    String? currentCtc,
    String? expectedCtc,
    String? noticePeriod,
  }) {
    return AppSettings(
      openAiApiKey: openAiApiKey ?? this.openAiApiKey,
      defaultResumeId: defaultResumeId ?? this.defaultResumeId,
      themeMode: themeMode ?? this.themeMode,
      gmailAccountEmail: gmailAccountEmail ?? this.gmailAccountEmail,
      senderName: senderName ?? this.senderName,
      profileSummary: profileSummary ?? this.profileSummary,
      emailSignature: emailSignature ?? this.emailSignature,
      currentLocation: currentLocation ?? this.currentLocation,
      totalExperience: totalExperience ?? this.totalExperience,
      currentCtc: currentCtc ?? this.currentCtc,
      expectedCtc: expectedCtc ?? this.expectedCtc,
      noticePeriod: noticePeriod ?? this.noticePeriod,
    );
  }

  /// Returns a copy with the Gmail account cleared (disconnect). A dedicated
  /// method is used because `copyWith` cannot set a field back to `null`.
  AppSettings withGmailDisconnected() {
    return AppSettings(
      openAiApiKey: openAiApiKey,
      defaultResumeId: defaultResumeId,
      themeMode: themeMode,
      senderName: senderName,
      profileSummary: profileSummary,
      emailSignature: emailSignature,
      currentLocation: currentLocation,
      totalExperience: totalExperience,
      currentCtc: currentCtc,
      expectedCtc: expectedCtc,
      noticePeriod: noticePeriod,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        openAiApiKey,
        defaultResumeId,
        themeMode,
        gmailAccountEmail,
        senderName,
        profileSummary,
        emailSignature,
        currentLocation,
        totalExperience,
        currentCtc,
        expectedCtc,
        noticePeriod,
      ];
}
