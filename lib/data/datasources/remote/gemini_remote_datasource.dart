import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_apply_ai/core/constants/api_constants.dart';
import 'package:flutter_apply_ai/core/errors/exceptions.dart';
import 'package:flutter_apply_ai/core/network/dio_exception_mapper.dart';
import 'package:flutter_apply_ai/core/utils/app_logger.dart';
import 'package:flutter_apply_ai/core/utils/typedefs.dart';

/// Low-level Gemini client. Sends a `generateContent` request configured for
/// structured JSON output and returns the parsed JSON object from the model's
/// response. Knows nothing about job postings — it is a generic
/// "prompt + schema → JSON map" transport.
abstract interface class GeminiRemoteDataSource {
  Future<DataMap> generateStructuredJson({
    required String apiKey,
    required String systemInstruction,
    required String userContent,
    required DataMap responseSchema,
    double temperature = 0.2,
  });
}

class GeminiRemoteDataSourceImpl implements GeminiRemoteDataSource {
  GeminiRemoteDataSourceImpl({
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
      throw const AiException('Gemini API key is not configured.');
    }

    try {
      final Response<Map<String, dynamic>> response =
          await _dio.post<Map<String, dynamic>>(
        ApiConstants.geminiGenerateContentPath,
        queryParameters: <String, dynamic>{
          ApiConstants.apiKeyQueryParam: apiKey,
        },
        data: <String, dynamic>{
          'systemInstruction': <String, dynamic>{
            'parts': <DataMap>[
              <String, dynamic>{'text': systemInstruction},
            ],
          },
          'contents': <DataMap>[
            <String, dynamic>{
              'role': 'user',
              'parts': <DataMap>[
                <String, dynamic>{'text': userContent},
              ],
            },
          ],
          'generationConfig': <String, dynamic>{
            'responseMimeType': 'application/json',
            'responseSchema': responseSchema,
            'temperature': temperature,
          },
        },
      );

      final Map<String, dynamic>? body = response.data;
      if (body == null) {
        throw const AiException('Gemini returned an empty response.');
      }

      final String jsonText = _extractGeneratedText(body);
      final Object? decoded = jsonDecode(jsonText);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw const AiException('Gemini returned a non-object JSON payload.');
    } on DioException catch (error) {
      throw mapDioException(error, context: 'AI request');
    } on FormatException catch (error, stackTrace) {
      _logger.e('Failed to decode Gemini JSON', error, stackTrace);
      throw AiException('Failed to parse the AI response.', error);
    }
  }

  /// Navigates the Gemini response envelope to the generated text part,
  /// surfacing safety blocks as [AiException]s.
  String _extractGeneratedText(Map<String, dynamic> body) {
    final Object? candidates = body['candidates'];
    if (candidates is List && candidates.isNotEmpty) {
      final Object? first = candidates.first;
      if (first is Map) {
        final Object? content = first['content'];
        if (content is Map) {
          final Object? parts = content['parts'];
          if (parts is List && parts.isNotEmpty) {
            final Object? part = parts.first;
            if (part is Map) {
              final Object? text = part['text'];
              if (text is String && text.trim().isNotEmpty) {
                return text;
              }
            }
          }
        }
      }
    }

    final Object? feedback = body['promptFeedback'];
    if (feedback is Map) {
      final Object? blockReason = feedback['blockReason'];
      if (blockReason != null) {
        throw AiException('The AI request was blocked: $blockReason.');
      }
    }

    throw const AiException('Gemini response contained no generated content.');
  }
}
