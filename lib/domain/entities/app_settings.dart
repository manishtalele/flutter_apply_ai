import 'package:equatable/equatable.dart';
import 'package:flutter_apply_ai/domain/entities/enums/app_theme_mode.dart';

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
  }) {
    return AppSettings(
      openAiApiKey: openAiApiKey ?? this.openAiApiKey,
      defaultResumeId: defaultResumeId ?? this.defaultResumeId,
      themeMode: themeMode ?? this.themeMode,
      gmailAccountEmail: gmailAccountEmail ?? this.gmailAccountEmail,
      senderName: senderName ?? this.senderName,
      profileSummary: profileSummary ?? this.profileSummary,
      emailSignature: emailSignature ?? this.emailSignature,
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
      ];
}
