import 'package:flutter_apply_ai/domain/entities/app_settings.dart';
import 'package:flutter_apply_ai/domain/entities/enums/app_theme_mode.dart';

/// Data-layer DTO for [AppSettings].
///
/// Only NON-SECRET fields are serialized here (theme, default resume, Gmail
/// account label, sender name). The OpenAI API key is intentionally excluded
/// from this JSON — it is persisted separately via secure storage and injected
/// back through [fromPrefsJson]'s `openAiApiKey` argument. This keeps secrets
/// out of SharedPreferences by construction.
class AppSettingsModel extends AppSettings {
  const AppSettingsModel({
    super.openAiApiKey,
    super.defaultResumeId,
    super.themeMode,
    super.gmailAccountEmail,
    super.senderName,
    super.profileSummary,
  });

  factory AppSettingsModel.fromEntity(AppSettings entity) {
    return AppSettingsModel(
      openAiApiKey: entity.openAiApiKey,
      defaultResumeId: entity.defaultResumeId,
      themeMode: entity.themeMode,
      gmailAccountEmail: entity.gmailAccountEmail,
      senderName: entity.senderName,
      profileSummary: entity.profileSummary,
    );
  }

  /// Reconstructs settings from the persisted non-secret bundle, re-attaching
  /// the securely-stored [openAiApiKey].
  factory AppSettingsModel.fromPrefsJson(
    Map<String, dynamic> json, {
    required String openAiApiKey,
  }) {
    return AppSettingsModel(
      openAiApiKey: openAiApiKey,
      defaultResumeId: json['defaultResumeId'] as String?,
      themeMode: AppThemeMode.fromValue(
        (json['themeMode'] as String?) ?? AppThemeMode.dark.value,
      ),
      gmailAccountEmail: json['gmailAccountEmail'] as String?,
      senderName: (json['senderName'] as String?) ?? '',
      profileSummary: (json['profileSummary'] as String?) ?? '',
    );
  }

  /// The non-secret bundle written to SharedPreferences.
  Map<String, dynamic> toPrefsJson() {
    return <String, dynamic>{
      'themeMode': themeMode.value,
      'defaultResumeId': defaultResumeId,
      'gmailAccountEmail': gmailAccountEmail,
      'senderName': senderName,
      'profileSummary': profileSummary,
    };
  }
}
