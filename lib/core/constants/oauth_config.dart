/// Google OAuth2 "Desktop app" client configuration.
///
/// For an installed/desktop app these credentials are NOT confidential secrets
/// (RFC 8252) — the security comes from PKCE + the loopback redirect. They are
/// supplied at build time via `--dart-define` so they are never hardcoded in
/// source control:
///
///   flutter run -d windows \
///     --dart-define=GOOGLE_OAUTH_CLIENT_ID=xxxx.apps.googleusercontent.com \
///     --dart-define=GOOGLE_OAUTH_CLIENT_SECRET=yyyy
///
/// Create the credentials at https://console.cloud.google.com/apis/credentials
/// (OAuth client ID → Desktop app) with the Gmail API enabled.
abstract final class OAuthConfig {
  const OAuthConfig._();

  static const String clientId = String.fromEnvironment(
    'GOOGLE_OAUTH_CLIENT_ID',
  );

  static const String clientSecret = String.fromEnvironment(
    'GOOGLE_OAUTH_CLIENT_SECRET',
  );

  static const String loopbackHost = '127.0.0.1';

  static const String revokeEndpoint = 'https://oauth2.googleapis.com/revoke';

  static bool get isConfigured => clientId.isNotEmpty;
}
