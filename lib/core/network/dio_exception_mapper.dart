import 'package:dio/dio.dart';
import 'package:flutter_apply_ai/core/errors/exceptions.dart';

/// Translates a Dio transport error into a typed [AppException]
/// ([NetworkException] for transport issues, [ServerException] for non-2xx
/// responses). Shared by all remote datasources so error handling is DRY and
/// consistent. [context] labels the operation in messages (e.g. "AI request",
/// "Gmail request").
AppException mapDioException(DioException error, {required String context}) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return NetworkException('The $context timed out.', error);
    case DioExceptionType.connectionError:
      return NetworkException(
        'Could not reach the server. Check your connection.',
        error,
      );
    case DioExceptionType.badCertificate:
      return const NetworkException('The server certificate was rejected.');
    case DioExceptionType.cancel:
      return NetworkException('The $context was cancelled.', error);
    case DioExceptionType.badResponse:
    case DioExceptionType.unknown:
      final int? statusCode = error.response?.statusCode;
      final String message = extractApiErrorMessage(error.response?.data) ??
          'The server returned an error'
              '${statusCode == null ? '' : ' ($statusCode)'}.';
      return ServerException(message, statusCode: statusCode, cause: error);
  }
}

/// Best-effort extraction of a human-readable message from a Google API error
/// body of the shape `{ "error": { "message": "..." } }` (or a plain
/// `{ "error": "..." }`).
String? extractApiErrorMessage(Object? data) {
  if (data is Map) {
    final Object? error = data['error'];
    if (error is Map) {
      final Object? message = error['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }
    if (error is String && error.isNotEmpty) {
      return error;
    }
  }
  return null;
}
