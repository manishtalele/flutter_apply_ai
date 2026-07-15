import 'package:dio/dio.dart';
import 'package:flutter_apply_ai/core/constants/api_constants.dart';
import 'package:flutter_apply_ai/core/errors/exceptions.dart';
import 'package:flutter_apply_ai/core/network/dio_exception_mapper.dart';
import 'package:flutter_apply_ai/core/utils/typedefs.dart';

/// Result of sending a Gmail message.
class GmailSendResult {
  const GmailSendResult({required this.messageId, required this.threadId});

  final String messageId;
  final String threadId;
}

/// Thin wrapper over the Gmail REST API. The bearer token is injected by the
/// [AuthInterceptor] on the underlying [Dio]; this class only shapes
/// requests/responses. Errors are mapped via [mapDioException].
abstract interface class GmailRemoteDataSource {
  /// The authenticated account's email address (`users.getProfile`).
  Future<String> getProfileEmail();

  /// Sends a pre-built base64url RFC 2822 message (`messages.send`).
  Future<GmailSendResult> sendRawMessage(String rawBase64Url);

  /// Fetches a full thread (`threads.get?format=full`).
  Future<DataMap> getThread(String threadId);
}

class GmailRemoteDataSourceImpl implements GmailRemoteDataSource {
  GmailRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<String> getProfileEmail() async {
    try {
      final Response<Map<String, dynamic>> response =
          await _dio.get<Map<String, dynamic>>(ApiConstants.gmailProfilePath);
      final Object? email = response.data?['emailAddress'];
      if (email is String && email.isNotEmpty) {
        return email;
      }
      throw const GmailException('Gmail profile did not include an email.');
    } on DioException catch (error) {
      throw mapDioException(error, context: 'Gmail profile request');
    }
  }

  @override
  Future<GmailSendResult> sendRawMessage(String rawBase64Url) async {
    try {
      final Response<Map<String, dynamic>> response =
          await _dio.post<Map<String, dynamic>>(
        ApiConstants.gmailSendPath,
        data: <String, dynamic>{'raw': rawBase64Url},
      );
      final Map<String, dynamic>? data = response.data;
      final Object? id = data?['id'];
      final Object? threadId = data?['threadId'];
      if (id is String && threadId is String) {
        return GmailSendResult(messageId: id, threadId: threadId);
      }
      throw const GmailException('Gmail send response was malformed.');
    } on DioException catch (error) {
      throw mapDioException(error, context: 'Gmail send request');
    }
  }

  @override
  Future<DataMap> getThread(String threadId) async {
    try {
      final Response<Map<String, dynamic>> response =
          await _dio.get<Map<String, dynamic>>(
        '${ApiConstants.gmailThreadsPath}/$threadId',
        queryParameters: <String, dynamic>{'format': 'full'},
      );
      final Map<String, dynamic>? data = response.data;
      if (data == null) {
        throw const GmailException('Gmail returned an empty thread.');
      }
      return data;
    } on DioException catch (error) {
      throw mapDioException(error, context: 'Gmail thread request');
    }
  }
}
