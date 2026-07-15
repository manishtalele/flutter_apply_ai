import 'package:dio/dio.dart';
import 'package:flutter_apply_ai/core/constants/api_constants.dart';
import 'package:flutter_apply_ai/core/errors/exceptions.dart';
import 'package:flutter_apply_ai/data/datasources/remote/gmail_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

Response<Map<String, dynamic>> _ok(String path, Map<String, dynamic> data) {
  return Response<Map<String, dynamic>>(
    requestOptions: RequestOptions(path: path),
    statusCode: 200,
    data: data,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  late _MockDio dio;
  late GmailRemoteDataSource dataSource;

  setUp(() {
    dio = _MockDio();
    dataSource = GmailRemoteDataSourceImpl(dio: dio);
  });

  test('getProfileEmail returns the account email', () async {
    when(() => dio.get<Map<String, dynamic>>(ApiConstants.gmailProfilePath))
        .thenAnswer(
      (_) async => _ok(
        ApiConstants.gmailProfilePath,
        <String, dynamic>{'emailAddress': 'me@gmail.com'},
      ),
    );

    expect(await dataSource.getProfileEmail(), 'me@gmail.com');
  });

  test('sendRawMessage parses id and threadId', () async {
    when(
      () => dio.post<Map<String, dynamic>>(
        ApiConstants.gmailSendPath,
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => _ok(
        ApiConstants.gmailSendPath,
        <String, dynamic>{'id': 'msg-1', 'threadId': 'thr-1'},
      ),
    );

    final GmailSendResult result = await dataSource.sendRawMessage('rawdata');
    expect(result.messageId, 'msg-1');
    expect(result.threadId, 'thr-1');
  });

  test('maps a 403 send error to ServerException with the API message',
      () async {
    when(
      () => dio.post<Map<String, dynamic>>(
        ApiConstants.gmailSendPath,
        data: any(named: 'data'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: ApiConstants.gmailSendPath),
        type: DioExceptionType.badResponse,
        response: Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: ApiConstants.gmailSendPath),
          statusCode: 403,
          data: <String, dynamic>{
            'error': <String, dynamic>{'message': 'Insufficient permission'},
          },
        ),
      ),
    );

    await expectLater(
      () => dataSource.sendRawMessage('rawdata'),
      throwsA(
        isA<ServerException>()
            .having((ServerException e) => e.statusCode, 'statusCode', 403)
            .having(
              (ServerException e) => e.message,
              'message',
              'Insufficient permission',
            ),
      ),
    );
  });

  test('throws GmailException when profile response is malformed', () async {
    when(() => dio.get<Map<String, dynamic>>(ApiConstants.gmailProfilePath))
        .thenAnswer(
      (_) async => _ok(ApiConstants.gmailProfilePath, <String, dynamic>{}),
    );

    expect(dataSource.getProfileEmail, throwsA(isA<GmailException>()));
  });
}
