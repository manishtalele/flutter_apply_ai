import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_apply_ai/core/constants/api_constants.dart';
import 'package:flutter_apply_ai/core/constants/oauth_config.dart';
import 'package:flutter_apply_ai/core/errors/exceptions.dart';
import 'package:flutter_apply_ai/core/network/dio_exception_mapper.dart';
import 'package:flutter_apply_ai/core/utils/app_logger.dart';
import 'package:flutter_apply_ai/data/datasources/remote/gmail_token_store.dart';
import 'package:url_launcher/url_launcher.dart';

/// Performs the OAuth2 Authorization Code flow with PKCE using a loopback
/// (`http://127.0.0.1:<port>`) redirect — the correct pattern for a native
/// desktop app (RFC 8252). Exchanges/refreshes tokens against Google's token
/// endpoint.
abstract interface class GmailAuthService {
  /// Runs the interactive consent flow and returns the resulting tokens.
  Future<GmailTokens> authorize();

  /// Refreshes and persists the access token; returns the new access token, or
  /// `null` if refresh is not possible.
  Future<String?> refreshAccessToken();

  /// Best-effort revoke of the stored tokens at Google (ignores failures).
  Future<void> revoke();
}

class GmailOAuthService implements GmailAuthService {
  GmailOAuthService({
    required Dio authDio,
    required GmailTokenStore tokenStore,
    required AppLogger logger,
  })  : _dio = authDio,
        _tokenStore = tokenStore,
        _logger = logger;

  final Dio _dio;
  final GmailTokenStore _tokenStore;
  final AppLogger _logger;

  static const String _pkceCharset =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';

  @override
  Future<GmailTokens> authorize() async {
    if (!OAuthConfig.isConfigured) {
      throw const AuthException(
        'Google OAuth client is not configured. Provide '
        'GOOGLE_OAUTH_CLIENT_ID via --dart-define.',
      );
    }

    final String codeVerifier = _generateCodeVerifier();
    final String codeChallenge = _deriveCodeChallenge(codeVerifier);

    final HttpServer server =
        await HttpServer.bind(OAuthConfig.loopbackHost, 0);
    final String redirectUri =
        'http://${OAuthConfig.loopbackHost}:${server.port}';

    try {
      final Uri authUrl = Uri.parse(ApiConstants.googleAuthEndpoint).replace(
        queryParameters: <String, String>{
          'client_id': OAuthConfig.clientId,
          'redirect_uri': redirectUri,
          'response_type': 'code',
          'scope': ApiConstants.gmailScopes.join(' '),
          'code_challenge': codeChallenge,
          'code_challenge_method': 'S256',
          'access_type': 'offline',
          'prompt': 'consent',
        },
      );

      if (!await launchUrl(authUrl, mode: LaunchMode.externalApplication)) {
        throw const AuthException('Could not open the browser for sign-in.');
      }

      final String code = await _awaitAuthorizationCode(server);
      return await _exchangeCodeForTokens(
        code: code,
        codeVerifier: codeVerifier,
        redirectUri: redirectUri,
      );
    } finally {
      await server.close(force: true);
    }
  }

  @override
  Future<String?> refreshAccessToken() async {
    final GmailTokens? current = await _tokenStore.read();
    final String? refreshToken = current?.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }

    try {
      final Response<Map<String, dynamic>> response =
          await _dio.post<Map<String, dynamic>>(
        ApiConstants.googleTokenEndpoint,
        options: Options(contentType: Headers.formUrlEncodedContentType),
        data: <String, String>{
          'client_id': OAuthConfig.clientId,
          'client_secret': OAuthConfig.clientSecret,
          'refresh_token': refreshToken,
          'grant_type': 'refresh_token',
        },
      );
      final GmailTokens refreshed = _parseTokenResponse(
        response.data,
        fallbackRefreshToken: refreshToken,
      );
      await _tokenStore.save(refreshed);
      return refreshed.accessToken;
    } on DioException catch (error) {
      final _GoogleAuthError googleError = _GoogleAuthError.from(error);
      _logger.w('Gmail token refresh failed — $googleError', error);

      if (googleError.isDeadRefreshToken) {
        // The refresh token will never work again (revoked, expired, or issued
        // by a different client). Drop it so the app reports "not connected"
        // and prompts a fresh sign-in, instead of retrying it on every
        // request and failing with a confusing 401.
        _logger.w('Clearing the dead Gmail refresh token — reconnect required.');
        await _tokenStore.clear();
      }
      return null;
    }
  }

  @override
  Future<void> revoke() async {
    final GmailTokens? current = await _tokenStore.read();
    final String? token = current?.refreshToken ?? current?.accessToken;
    if (token == null || token.isEmpty) {
      return;
    }
    try {
      await _dio.post<dynamic>(
        OAuthConfig.revokeEndpoint,
        options: Options(contentType: Headers.formUrlEncodedContentType),
        data: <String, String>{'token': token},
      );
    } on DioException catch (error) {
      _logger.w('Gmail token revoke failed (ignored)', error);
    }
  }

  Future<String> _awaitAuthorizationCode(HttpServer server) async {
    await for (final HttpRequest request in server) {
      final Uri uri = request.uri;
      final String? code = uri.queryParameters['code'];
      final String? error = uri.queryParameters['error'];

      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.html
        ..write(_resultPage(success: error == null && code != null));
      await request.response.close();

      if (error != null) {
        throw AuthException('Authorization was denied: $error.');
      }
      if (code != null && code.isNotEmpty) {
        return code;
      }
    }
    throw const AuthException('Sign-in was closed before completing.');
  }

  Future<GmailTokens> _exchangeCodeForTokens({
    required String code,
    required String codeVerifier,
    required String redirectUri,
  }) async {
    try {
      final Response<Map<String, dynamic>> response =
          await _dio.post<Map<String, dynamic>>(
        ApiConstants.googleTokenEndpoint,
        options: Options(contentType: Headers.formUrlEncodedContentType),
        data: <String, String>{
          'client_id': OAuthConfig.clientId,
          'client_secret': OAuthConfig.clientSecret,
          'code': code,
          'code_verifier': codeVerifier,
          'grant_type': 'authorization_code',
          'redirect_uri': redirectUri,
        },
      );
      return _parseTokenResponse(response.data);
    } on DioException catch (error) {
      throw mapDioException(error, context: 'Gmail sign-in');
    }
  }

  GmailTokens _parseTokenResponse(
    Map<String, dynamic>? data, {
    String? fallbackRefreshToken,
  }) {
    if (data == null) {
      throw const AuthException('Empty token response from Google.');
    }
    final Object? accessToken = data['access_token'];
    if (accessToken is! String || accessToken.isEmpty) {
      throw const AuthException('Google did not return an access token.');
    }
    final Object? refreshToken = data['refresh_token'];
    final Object? expiresIn = data['expires_in'];
    final int seconds = expiresIn is num ? expiresIn.toInt() : 3600;

    return GmailTokens(
      accessToken: accessToken,
      refreshToken: refreshToken is String && refreshToken.isNotEmpty
          ? refreshToken
          : fallbackRefreshToken,
      expiry: DateTime.now().add(Duration(seconds: seconds)),
    );
  }

  String _generateCodeVerifier() {
    final Random random = Random.secure();
    return List<String>.generate(
      96,
      (_) => _pkceCharset[random.nextInt(_pkceCharset.length)],
    ).join();
  }

  String _deriveCodeChallenge(String verifier) {
    final Digest digest = sha256.convert(ascii.encode(verifier));
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  /// Renders the OAuth loopback landing page shown in the user's browser.
  String _resultPage({required bool success}) {
    final String title = success ? 'Sign-in complete' : 'Sign-in failed';
    final String body = success
        ? 'You can close this tab and return to Flutter Apply AI.'
        : 'Something went wrong. Please return to the app and try again.';
    return '<!doctype html><html><head><meta charset="utf-8">'
        '<title>$title</title></head>'
        '<body style="font-family:sans-serif;text-align:center;padding:48px">'
        '<h2>$title</h2><p>$body</p></body></html>';
  }
}

/// The OAuth2 error payload Google's token endpoint returns alongside a 4xx:
/// `{"error": "invalid_grant", "error_description": "Token has been expired
/// or revoked."}`.
///
/// Without surfacing this, every token failure looks like an indistinguishable
/// "400" in the logs — a dead refresh token and a misconfigured client are
/// very different problems with very different fixes.
class _GoogleAuthError {
  const _GoogleAuthError({this.code, this.description});

  factory _GoogleAuthError.from(DioException error) {
    final Object? data = error.response?.data;
    if (data is Map) {
      final Object? code = data['error'];
      final Object? description = data['error_description'];
      return _GoogleAuthError(
        code: code is String ? code : null,
        description: description is String ? description : null,
      );
    }
    return const _GoogleAuthError();
  }

  final String? code;
  final String? description;

  /// True when the refresh token itself is permanently unusable, so retrying
  /// is pointless and only a fresh sign-in can recover.
  ///
  /// Google returns `invalid_grant` when the token was revoked, when the user
  /// changed their password, or when it simply expired — which happens after
  /// 7 days for an OAuth app still in "Testing" publishing status.
  bool get isDeadRefreshToken => code == 'invalid_grant';

  @override
  String toString() {
    if (code == null) {
      return 'no OAuth error code in the response';
    }
    return description == null ? code! : '$code: $description';
  }
}
