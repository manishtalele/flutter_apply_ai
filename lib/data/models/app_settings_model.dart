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
    super.emailSignature,
    super.currentLocation,
    super.totalExperience,
    super.currentCtc,
    super.expectedCtc,
    super.noticePeriod,
  });

  factory AppSettingsModel.fromEntity(AppSettings entity) {
    return AppSettingsModel(
      openAiApiKey: entity.openAiApiKey,
      defaultResumeId: entity.defaultResumeId,
      themeMode: entity.themeMode,
      gmailAccountEmail: entity.gmailAccountEmail,
      senderName: entity.senderName,
      profileSummary: entity.profileSummary,
      emailSignature: entity.emailSignature,
      currentLocation: entity.currentLocation,
      totalExperience: entity.totalExperience,
      currentCtc: entity.currentCtc,
      expectedCtc: entity.expectedCtc,
      noticePeriod: entity.noticePeriod,
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
      emailSignature: (json['emailSignature'] as String?) ?? '',
      // Added after v1 of the bundle — absent for users upgrading, hence the
      // null-coalescing defaults rather than a bundle version bump.
      currentLocation: (json['currentLocation'] as String?) ?? '',
      totalExperience: (json['totalExperience'] as String?) ?? '',
      currentCtc: (json['currentCtc'] as String?) ?? '',
      expectedCtc: (json['expectedCtc'] as String?) ?? '',
      noticePeriod: (json['noticePeriod'] as String?) ?? '',
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
      'emailSignature': emailSignature,
      'currentLocation': currentLocation,
      'totalExperience': totalExperience,
      'currentCtc': currentCtc,
      'expectedCtc': expectedCtc,
      'noticePeriod': noticePeriod,
    };
  }
}
