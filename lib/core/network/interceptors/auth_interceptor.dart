import 'package:dio/dio.dart';
import 'package:flutter_apply_ai/core/utils/app_logger.dart';

/// Supplies the current OAuth access token (or `null` if not authenticated).
typedef AccessTokenProvider = Future<String?> Function();

/// Attempts a token refresh and returns a fresh access token, or `null` if
/// refresh is impossible (no refresh token / revoked).
typedef TokenRefresher = Future<String?> Function();

/// Injects the Gmail bearer token on every request and transparently refreshes
/// it once on a 401, replaying the original request with the new token.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required AccessTokenProvider tokenProvider,
    required AppLogger logger,
    TokenRefresher? refresher,
  })  : _tokenProvider = tokenProvider,
        _logger = logger,
        _refresher = refresher;

  final AccessTokenProvider _tokenProvider;
  final TokenRefresher? _refresher;
  final AppLogger _logger;

  static const String _retriedFlag = 'auth_retried';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final String? token = await _tokenProvider();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final bool unauthorized = err.response?.statusCode == 401;
    final bool alreadyRetried = err.requestOptions.extra[_retriedFlag] == true;
    final TokenRefresher? refresher = _refresher;

    if (unauthorized && refresher != null && !alreadyRetried) {
      _logger.i('Gmail 401 received — attempting token refresh.');
      final String? refreshed = await refresher();
      if (refreshed != null && refreshed.isNotEmpty) {
        final RequestOptions retryOptions = err.requestOptions
          ..headers['Authorization'] = 'Bearer $refreshed'
          ..extra[_retriedFlag] = true;
        try {
          final Response<dynamic> response =
              await Dio().fetch<dynamic>(retryOptions);
          handler.resolve(response);
          return;
        } catch (retryError) {
          _logger.w('Retry after refresh failed', retryError);
        }
      }
    }
    handler.next(err);
  }
}
