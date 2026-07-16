import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_apply_ai/core/constants/api_constants.dart';
import 'package:flutter_apply_ai/core/errors/exceptions.dart';
import 'package:flutter_apply_ai/core/utils/app_logger.dart';
import 'package:flutter_apply_ai/core/utils/typedefs.dart';
import 'package:flutter_apply_ai/data/datasources/remote/openai_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

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

/// Builds an OpenAI Responses-API envelope whose output text is [text].
Response<Map<String, dynamic>> _response(String text) {
  return Response<Map<String, dynamic>>(
    requestOptions: RequestOptions(path: ApiConstants.openAiResponsesPath),
    statusCode: 200,
    data: <String, dynamic>{
      'output': <dynamic>[
        <String, dynamic>{
          'content': <dynamic>[
            <String, dynamic>{'type': 'output_text', 'text': text},
          ],
        },
      ],
    },
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(Options());
  });

  late _MockDio dio;
  late OpenAiRemoteDataSource dataSource;

  setUp(() {
    dio = _MockDio();
    dataSource = OpenAiRemoteDataSourceImpl(
      dio: dio,
      logger: const _SilentLogger(),
    );
  });

  const DataMap schema = <String, dynamic>{'type': 'object'};

  Future<DataMap> call() {
    return dataSource.generateStructuredJson(
      apiKey: 'sk-test-key',
      systemInstruction: 'system',
      userContent: 'content',
      responseSchema: schema,
    );
  }

  void stubPost(Response<Map<String, dynamic>> response) {
    when(
      () => dio.post<Map<String, dynamic>>(
        ApiConstants.openAiResponsesPath,
        data: any(named: 'data'),
        options: any(named: 'options'),
      ),
    ).thenAnswer((_) async => response);
  }

  test('parses the output_text JSON into a map', () async {
    stubPost(_response(jsonEncode(<String, dynamic>{'outcome': 'interview'})));
    final DataMap result = await call();
    expect(result['outcome'], 'interview');
  });

  test('throws AiException immediately when the API key is empty', () async {
    expect(
      () => dataSource.generateStructuredJson(
        apiKey: '  ',
        systemInstruction: 's',
        userContent: 'c',
        responseSchema: schema,
      ),
      throwsA(isA<AiException>()),
    );
    verifyNever(
      () => dio.post<Map<String, dynamic>>(
        any(),
        data: any(named: 'data'),
        options: any(named: 'options'),
      ),
    );
  });

  test('maps a 401 to ServerException with the API message', () async {
    when(
      () => dio.post<Map<String, dynamic>>(
        ApiConstants.openAiResponsesPath,
        data: any(named: 'data'),
        options: any(named: 'options'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: ApiConstants.openAiResponsesPath),
        type: DioExceptionType.badResponse,
        response: Response<Map<String, dynamic>>(
          requestOptions:
              RequestOptions(path: ApiConstants.openAiResponsesPath),
          statusCode: 401,
          data: <String, dynamic>{
            'error': <String, dynamic>{'message': 'Invalid API key'},
          },
        ),
      ),
    );

    await expectLater(
      call,
      throwsA(
        isA<ServerException>()
            .having((ServerException e) => e.statusCode, 'statusCode', 401)
            .having(
              (ServerException e) => e.message,
              'message',
              'Invalid API key',
            ),
      ),
    );
  });
}
