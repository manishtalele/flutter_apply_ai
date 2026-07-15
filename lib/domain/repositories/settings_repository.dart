import 'package:flutter_apply_ai/core/utils/typedefs.dart';
import 'package:flutter_apply_ai/domain/entities/app_settings.dart';

/// Settings contract. Non-secret fields persist to SharedPreferences; the
/// Gemini API key is handled separately via secure storage.
abstract interface class SettingsRepository {
  /// Loads the full settings, merging the securely-stored API key with the
  /// non-secret preferences bundle.
  ResultFuture<AppSettings> getSettings();

  /// Persists only the non-secret fields (theme, default resume, Gmail account
  /// label, sender name). The API key is NOT written by this method.
  ResultFuture<void> saveSettings(AppSettings settings);

  /// Returns the stored Gemini API key, or an empty string if none is set.
  ResultFuture<String> getGeminiApiKey();

  ResultFuture<void> saveGeminiApiKey(String apiKey);

  ResultFuture<void> clearGeminiApiKey();
}
