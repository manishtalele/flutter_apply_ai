import 'package:dio/dio.dart';
import 'package:flutter_apply_ai/core/constants/app_constants.dart';
import 'package:flutter_apply_ai/core/network/interceptors/logging_interceptor.dart';
import 'package:flutter_apply_ai/core/utils/app_logger.dart';

/// Factory for pre-configured [Dio] instances (timeouts + JSON + logging).
///
/// A separate client is created per remote host (Gemini, Gmail) because they
/// use different base URLs and auth mechanisms. Additional per-client
/// interceptors (e.g. the Gmail bearer-token interceptor in Module 10) can be
/// passed via [extraInterceptors].
class DioClient {
  DioClient({required AppLogger logger}) : _logger = logger;

  final AppLogger _logger;

  Dio create({
    required String baseUrl,
    List<Interceptor> extraInterceptors = const <Interceptor>[],
  }) {
    final Dio dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        sendTimeout: AppConstants.sendTimeout,
        responseType: ResponseType.json,
        contentType: Headers.jsonContentType,
      ),
    );
    dio.interceptors.add(LoggingInterceptor(logger: _logger));
    dio.interceptors.addAll(extraInterceptors);
    return dio;
  }
}
