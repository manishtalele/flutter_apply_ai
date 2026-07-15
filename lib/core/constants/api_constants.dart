/// Remote API endpoints and identifiers for Gemini and Gmail/OAuth2.
///
/// The Gemini API key is passed as a query parameter at call time (never
/// stored here). Gmail/OAuth constants are defined now and consumed in
/// Modules 10/16/17.
abstract final class ApiConstants {
  const ApiConstants._();

  // ── Gemini (Generative Language API) ─────────────────────────────────
  static const String openAiBaseUrl = 'https://api.openai.com';
  static const String openAiModel = 'gpt-5.6';
  static const String openAiResponsesPath = '/v1/responses';

  // ── Gmail REST API ───────────────────────────────────────────────────
  static const String gmailBaseUrl = 'https://gmail.googleapis.com';
  static const String gmailSendPath = '/gmail/v1/users/me/messages/send';
  static const String gmailThreadsPath = '/gmail/v1/users/me/threads';
  static const String gmailProfilePath = '/gmail/v1/users/me/profile';

  // ── Google OAuth2 (desktop loopback + PKCE) ──────────────────────────
  static const String googleAuthEndpoint =
      'https://accounts.google.com/o/oauth2/v2/auth';
  static const String googleTokenEndpoint =
      'https://oauth2.googleapis.com/token';
  static const List<String> gmailScopes = <String>[
    'https://www.googleapis.com/auth/gmail.send',
    'https://www.googleapis.com/auth/gmail.readonly',
    'https://www.googleapis.com/auth/userinfo.email',
  ];
}
