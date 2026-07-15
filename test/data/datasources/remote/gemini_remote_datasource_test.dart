import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_apply_ai/core/constants/api_constants.dart';
import 'package:flutter_apply_ai/core/errors/exceptions.dart';
import 'package:flutter_apply_ai/core/utils/app_logger.dart';
import 'package:flutter_apply_ai/core/utils/typedefs.dart';
import 'package:flutter_apply_ai/data/datasources/remote/gemini_remote_datasource.dart';
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

Response<Map<String, dynamic>> _response(Map<String, dynamic> data) {
  return Response<Map<String, dynamic>>(
    requestOptions: RequestOptions(path: ApiConstants.geminiGenerateContentPath),
    statusCode: 200,
    data: data,
  );
}

Map<String, dynamic> _envelope(String text) {
  return <String, dynamic>{
    'candidates': <dynamic>[
      <String, dynamic>{
        'content': <String, dynamic>{
          'parts': <dynamic>[
            <String, dynamic>{'text': text},
          ],
        },
      },
    ],
  };
}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  late _MockDio dio;
  late GeminiRemoteDataSource dataSource;

  setUp(() {
    dio = _MockDio();
    dataSource = GeminiRemoteDataSourceImpl(
      dio: dio,
      logger: const _SilentLogger(),
    );
  });

  const DataMap schema = <String, dynamic>{'type': 'OBJECT'};

  Future<DataMap> callDataSource() {
    return dataSource.generateStructuredJson(
      apiKey: 'test-key',
      systemInstruction: 'system',
      userContent: 'content',
      responseSchema: schema,
    );
  }

  void stubPost(Response<Map<String, dynamic>> response) {
    when(
      () => dio.post<Map<String, dynamic>>(
        ApiConstants.geminiGenerateContentPath,
        queryParameters: any(named: 'queryParameters'),
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) async => response);
  }

  void stubPostThrows(DioException exception) {
    when(
      () => dio.post<Map<String, dynamic>>(
        ApiConstants.geminiGenerateContentPath,
        queryParameters: any(named: 'queryParameters'),
        data: any(named: 'data'),
      ),
    ).thenThrow(exception);
  }

  test('parses the generated JSON text into a map', () async {
    stubPost(
      _response(_envelope(jsonEncode(<String, dynamic>{'outcome': 'interview'}))),
    );

    final DataMap result = await callDataSource();

    expect(result['outcome'], 'interview');
  });

  test('throws AiException when the request is safety-blocked', () async {
    stubPost(
      _response(<String, dynamic>{
        'promptFeedback': <String, dynamic>{'blockReason': 'SAFETY'},
      }),
    );

    expect(callDataSource, throwsA(isA<AiException>()));
  });

  test('throws AiException immediately when the API key is empty', () async {
    expect(
      () => dataSource.generateStructuredJson(
        apiKey: '   ',
        systemInstruction: 'system',
        userContent: 'content',
        responseSchema: schema,
      ),
      throwsA(isA<AiException>()),
    );
    verifyNever(
      () => dio.post<Map<String, dynamic>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
        data: any(named: 'data'),
      ),
    );
  });

  test('maps a bad HTTP response to ServerException with the API message',
      () async {
    stubPostThrows(
      DioException(
        requestOptions:
            RequestOptions(path: ApiConstants.geminiGenerateContentPath),
        type: DioExceptionType.badResponse,
        response: Response<Map<String, dynamic>>(
          requestOptions:
              RequestOptions(path: ApiConstants.geminiGenerateContentPath),
          statusCode: 400,
          data: <String, dynamic>{
            'error': <String, dynamic>{'message': 'API key not valid'},
          },
        ),
      ),
    );

    await expectLater(
      callDataSource,
      throwsA(
        isA<ServerException>()
            .having((ServerException e) => e.statusCode, 'statusCode', 400)
            .having(
              (ServerException e) => e.message,
              'message',
              'API key not valid',
            ),
      ),
    );
  });

  test('maps a timeout to NetworkException', () async {
    stubPostThrows(
      DioException(
        requestOptions:
            RequestOptions(path: ApiConstants.geminiGenerateContentPath),
        type: DioExceptionType.connectionTimeout,
      ),
    );

    expect(callDataSource, throwsA(isA<NetworkException>()));
  });
}
