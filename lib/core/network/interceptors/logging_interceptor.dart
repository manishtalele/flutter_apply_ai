import 'package:dio/dio.dart';
import 'package:flutter_apply_ai/core/utils/app_logger.dart';

/// Dio interceptor that logs request/response/error lifecycle for diagnostics.
///
/// Deliberately logs only the method and *path* (never the full URI, query
/// string, or headers) so secrets — the OpenAI API key (Bearer token) and
/// Gmail OAuth tokens — are never written to logs.
class LoggingInterceptor extends Interceptor {
  LoggingInterceptor({required AppLogger logger}) : _logger = logger;

  final AppLogger _logger;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    _logger.d('→ ${options.method} ${options.baseUrl}${options.path}');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _logger.d(
      '← ${response.statusCode} ${response.requestOptions.path}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.w(
      '✗ ${err.requestOptions.path} '
      '(${err.response?.statusCode ?? err.type.name})',
      err,
    );
    handler.next(err);
  }
}
