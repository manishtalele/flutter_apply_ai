import 'package:dio/dio.dart';
import 'package:flutter_apply_ai/core/constants/api_constants.dart';
import 'package:flutter_apply_ai/core/utils/app_logger.dart';
import 'package:flutter_apply_ai/data/datasources/remote/gmail_auth_service.dart';
import 'package:flutter_apply_ai/data/datasources/remote/gmail_token_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

class _MockTokenStore extends Mock implements GmailTokenStore {}

class _SilentLogger implements AppLogger {
  const _SilentLogger();

  @override
  void d(String message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void i(String message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void w(String message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void e(String message, [Object? error, StackTrace? stackTrace]) {}
}

GmailTokens _storedTokens() {
  return GmailTokens(
    accessToken: 'stale-access-token',
    refreshToken: 'the-refresh-token',
    expiry: DateTime.fromMillisecondsSinceEpoch(0),
  );
}

/// Builds the error Google's token endpoint returns for a 4xx.
DioException _tokenError({
  required int statusCode,
  required Map<String, dynamic> body,
}) {
  final RequestOptions options =
      RequestOptions(path: ApiConstants.googleTokenEndpoint);
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<Map<String, dynamic>>(
      requestOptions: options,
      statusCode: statusCode,
      data: body,
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      GmailTokens(accessToken: 'seed', refreshToken: null, expiry: DateTime(0)),
    );
  });

  late _MockDio dio;
  late _MockTokenStore tokenStore;
  late GmailOAuthService service;

  setUp(() {
    dio = _MockDio();
    tokenStore = _MockTokenStore();
    service = GmailOAuthService(
      authDio: dio,
      tokenStore: tokenStore,
      logger: const _SilentLogger(),
    );
    when(tokenStore.read).thenAnswer((_) async => _storedTokens());
    when(() => tokenStore.save(any())).thenAnswer((_) async {});
    when(tokenStore.clear).thenAnswer((_) async {});
  });

  test('discards the refresh token when Google reports invalid_grant', () async {
    when(
      () => dio.post<Map<String, dynamic>>(
        any(),
        data: any(named: 'data'),
        options: any(named: 'options'),
      ),
    ).thenThrow(
      _tokenError(
        statusCode: 400,
        body: <String, dynamic>{
          'error': 'invalid_grant',
          'error_description': 'Token has been expired or revoked.',
        },
      ),
    );

    final String? token = await service.refreshAccessToken();

    expect(token, isNull);
    // Cleared, so the app reports "not connected" and asks for a fresh sign-in
    // rather than retrying a token that can never work again.
    verify(tokenStore.clear).called(1);
  });

  test('keeps the refresh token when the failure may be transient', () async {
    when(
      () => dio.post<Map<String, dynamic>>(
        any(),
        data: any(named: 'data'),
        options: any(named: 'options'),
      ),
    ).thenThrow(
      _tokenError(
        statusCode: 500,
        body: <String, dynamic>{'error': 'internal_failure'},
      ),
    );

    final String? token = await service.refreshAccessToken();

    expect(token, isNull);
    verifyNever(tokenStore.clear);
  });

  test('returns null without calling Google when no refresh token is stored',
      () async {
    when(tokenStore.read).thenAnswer(
      (_) async => GmailTokens(
        accessToken: 'access-only',
        refreshToken: null,
        expiry: DateTime.fromMillisecondsSinceEpoch(0),
      ),
    );

    final String? token = await service.refreshAccessToken();

    expect(token, isNull);
    verifyNever(
      () => dio.post<Map<String, dynamic>>(
        any(),
        data: any(named: 'data'),
        options: any(named: 'options'),
      ),
    );
  });

  test('saves and returns the new access token on success', () async {
    final RequestOptions options =
        RequestOptions(path: ApiConstants.googleTokenEndpoint);
    when(
      () => dio.post<Map<String, dynamic>>(
        any(),
        data: any(named: 'data'),
        options: any(named: 'options'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: options,
        statusCode: 200,
        data: <String, dynamic>{
          'access_token': 'fresh-access-token',
          'expires_in': 3599,
        },
      ),
    );

    final String? token = await service.refreshAccessToken();

    expect(token, 'fresh-access-token');
    final GmailTokens saved =
        verify(() => tokenStore.save(captureAny())).captured.single
            as GmailTokens;
    // Google omits refresh_token on refresh responses — the existing one must
    // be carried forward, not dropped.
    expect(saved.refreshToken, 'the-refresh-token');
    verifyNever(tokenStore.clear);
  });
}
