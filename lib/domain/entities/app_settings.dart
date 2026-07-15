import 'package:equatable/equatable.dart';
import 'package:flutter_apply_ai/domain/entities/enums/app_theme_mode.dart';

/// User-configurable application settings.
///
/// [geminiApiKey] and Gmail credentials are secrets: the data layer persists
/// the key via secure storage and never in plain preferences. Non-secret
/// fields (theme, default resume, connected account label) go to
/// SharedPreferences.
class AppSettings extends Equatable {
  const AppSettings({
    this.geminiApiKey = '',
    this.defaultResumeId,
    this.themeMode = AppThemeMode.dark,
    this.gmailAccountEmail,
    this.senderName = '',
    this.profileSummary = '',
  });

  /// Empty/default settings for first launch.
  static const AppSettings empty = AppSettings();

  final String geminiApiKey;
  final String? defaultResumeId;
  final AppThemeMode themeMode;

  /// The connected Gmail account's address, or `null` when not connected.
  final String? gmailAccountEmail;

  /// Display name used as the email "From" name.
  final String senderName;

  /// Free-text summary of the candidate's skills/experience, fed to the AI to
  /// compute a meaningful match score.
  final String profileSummary;

  bool get hasGeminiKey => geminiApiKey.trim().isNotEmpty;

  bool get isGmailConnected =>
      gmailAccountEmail != null && gmailAccountEmail!.trim().isNotEmpty;

  AppSettings copyWith({
    String? geminiApiKey,
    String? defaultResumeId,
    AppThemeMode? themeMode,
    String? gmailAccountEmail,
    String? senderName,
    String? profileSummary,
  }) {
    return AppSettings(
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
      defaultResumeId: defaultResumeId ?? this.defaultResumeId,
      themeMode: themeMode ?? this.themeMode,
      gmailAccountEmail: gmailAccountEmail ?? this.gmailAccountEmail,
      senderName: senderName ?? this.senderName,
      profileSummary: profileSummary ?? this.profileSummary,
    );
  }

  /// Returns a copy with the Gmail account cleared (disconnect). A dedicated
  /// method is used because `copyWith` cannot set a field back to `null`.
  AppSettings withGmailDisconnected() {
    return AppSettings(
      geminiApiKey: geminiApiKey,
      defaultResumeId: defaultResumeId,
      themeMode: themeMode,
      senderName: senderName,
      profileSummary: profileSummary,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        geminiApiKey,
        defaultResumeId,
        themeMode,
        gmailAccountEmail,
        senderName,
        profileSummary,
      ];
}
