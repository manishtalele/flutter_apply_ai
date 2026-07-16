/// Keys for SharedPreferences (non-secret) and secure storage (secrets).
///
/// Secure keys are prefixed `secure_` purely for readability; they are stored
/// in a different backend (Windows Credential Manager via
/// `flutter_secure_storage`), never in SharedPreferences.
abstract final class StorageKeys {
  const StorageKeys._();

  // ── SharedPreferences (non-secret) ───────────────────────────────────
  /// Non-secret settings bundle (theme, default resume, Gmail account label,
  /// sender name) serialized as JSON.
  static const String settingsBundle = 'settings_bundle_v1';

  /// Resume profiles serialized as a JSON list.
  static const String resumesList = 'resumes_list_v1';

  // ── Secure storage (secrets) ─────────────────────────────────────────
  static const String secureOpenAiApiKey = 'secure_openai_api_key';
  static const String secureGmailAccessToken = 'secure_gmail_access_token';
  static const String secureGmailRefreshToken = 'secure_gmail_refresh_token';
  static const String secureGmailTokenExpiry = 'secure_gmail_token_expiry';
}
