/// Remote API endpoints and identifiers for OpenAI and Gmail/OAuth2.
///
/// The OpenAI API key is sent as a Bearer token at call time (never stored
/// here). Change [openAiModel] to any model your account can access that
/// supports the Responses API + structured outputs (e.g. `gpt-4o`,
/// `gpt-4.1`).
abstract final class ApiConstants {
  const ApiConstants._();

  // ── OpenAI (Responses API) ───────────────────────────────────────────
  static const String openAiBaseUrl = 'https://api.openai.com';
  static const String openAiModel = 'gpt-4o';
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
