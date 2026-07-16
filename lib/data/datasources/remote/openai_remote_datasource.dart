import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_apply_ai/core/constants/api_constants.dart';
import 'package:flutter_apply_ai/core/errors/exceptions.dart';
import 'package:flutter_apply_ai/core/network/dio_exception_mapper.dart';
import 'package:flutter_apply_ai/core/utils/app_logger.dart';
import 'package:flutter_apply_ai/core/utils/typedefs.dart';

/// OpenAI Responses API client for schema-constrained JSON generation.
abstract interface class OpenAiRemoteDataSource {
  Future<DataMap> generateStructuredJson({
    required String apiKey,
    required String systemInstruction,
    required String userContent,
    required DataMap responseSchema,
    double temperature = 0.2,
  });
}

class OpenAiRemoteDataSourceImpl implements OpenAiRemoteDataSource {
  OpenAiRemoteDataSourceImpl({
    required Dio dio,
    required AppLogger logger,
  })  : _dio = dio,
        _logger = logger;

  final Dio _dio;
  final AppLogger _logger;

  @override
  Future<DataMap> generateStructuredJson({
    required String apiKey,
    required String systemInstruction,
    required String userContent,
    required DataMap responseSchema,
    double temperature = 0.2,
  }) async {
    if (apiKey.trim().isEmpty) {
      throw const AiException('OpenAI API key is not configured.');
    }

    try {
      final Response<Map<String, dynamic>> response =
          await _dio.post<Map<String, dynamic>>(
        ApiConstants.openAiResponsesPath,
        options: Options(
          headers: <String, String>{
            'Authorization': 'Bearer ${apiKey.trim()}',
          },
        ),
        data: <String, dynamic>{
          'model': ApiConstants.openAiModel,
          'input': <DataMap>[
            <String, dynamic>{'role': 'system', 'content': systemInstruction},
            <String, dynamic>{'role': 'user', 'content': userContent},
          ],
          'text': <String, dynamic>{
            'format': <String, dynamic>{
              'type': 'json_schema',
              'name': 'job_analysis',
              'strict': true,
              'schema': responseSchema,
            },
          },
          // Temperature is intentionally omitted: some OpenAI models
          // (reasoning models) reject it, and the default suits extraction.
        },
      );

      final Map<String, dynamic>? body = response.data;
      if (body == null) {
        throw const AiException('OpenAI returned an empty response.');
      }

      final Object? decoded = jsonDecode(_extractOutputText(body));
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw const AiException('OpenAI returned a non-object JSON payload.');
    } on DioException catch (error) {
      throw mapDioException(error, context: 'OpenAI request');
    } on FormatException catch (error, stackTrace) {
      _logger.e('Failed to decode OpenAI JSON', error, stackTrace);
      throw AiException('Failed to parse the AI response.', error);
    }
  }

  String _extractOutputText(Map<String, dynamic> body) {
    final Object? output = body['output'];
    if (output is List) {
      for (final Object? item in output) {
        if (item is! Map) {
          continue;
        }
        final Object? content = item['content'];
        if (content is! List) {
          continue;
        }
        for (final Object? part in content) {
          if (part is Map && part['text'] is String) {
            final String text = part['text'] as String;
            if (text.trim().isNotEmpty) {
              return text;
            }
          }
        }
      }
    }

    throw const AiException('OpenAI response contained no generated content.');
  }
}
