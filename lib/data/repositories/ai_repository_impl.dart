import 'package:flutter_apply_ai/core/constants/prompt_constants.dart';
import 'package:flutter_apply_ai/core/errors/exceptions.dart';
import 'package:flutter_apply_ai/core/utils/app_logger.dart';
import 'package:flutter_apply_ai/core/utils/typedefs.dart';
import 'package:flutter_apply_ai/data/datasources/remote/openai_remote_datasource.dart';
import 'package:flutter_apply_ai/data/models/job_posting_model.dart';
import 'package:flutter_apply_ai/data/repositories/repository_error_mapper.dart';
import 'package:flutter_apply_ai/domain/entities/enums/reply_outcome.dart';
import 'package:flutter_apply_ai/domain/entities/job_posting.dart';
import 'package:flutter_apply_ai/domain/repositories/ai_repository.dart';
import 'package:flutter_apply_ai/domain/repositories/settings_repository.dart';

/// [AiRepository] backed by OpenAI. Composes the prompt/schema, retrieves the
/// API key from [SettingsRepository], and maps the structured JSON response
/// into domain entities. All errors funnel through [RepositoryErrorMapper].
class AiRepositoryImpl with RepositoryErrorMapper implements AiRepository {
  AiRepositoryImpl({
    required OpenAiRemoteDataSource remoteDataSource,
    required SettingsRepository settingsRepository,
    required AppLogger logger,
  })  : _remote = remoteDataSource,
        _settings = settingsRepository,
        _logger = logger;

  final OpenAiRemoteDataSource _remote;
  final SettingsRepository _settings;
  final AppLogger _logger;

  @override
  AppLogger get logger => _logger;

  @override
  ResultFuture<JobPosting> extractJobPosting(
    String rawText, {
    String candidateProfile = '',
  }) {
    return guard<JobPosting>(() async {
      if (rawText.trim().isEmpty) {
        throw const ValidationException('The job description is empty.');
      }
      final String apiKey = await _requireApiKey();

      final DataMap json = await _remote.generateStructuredJson(
        apiKey: apiKey,
        systemInstruction: PromptConstants.extractionSystemInstruction,
        userContent: PromptConstants.extractionUserContent(
          jobDescription: rawText,
          candidateProfile: candidateProfile,
        ),
        responseSchema: PromptConstants.jobPostingResponseSchema,
      );

      return JobPostingModel.fromJson(json);
    });
  }

  @override
  ResultFuture<ReplyOutcome> classifyReply(String emailBody) {
    return guard<ReplyOutcome>(() async {
      if (emailBody.trim().isEmpty) {
        return ReplyOutcome.none;
      }
      final String apiKey = await _requireApiKey();

      final DataMap json = await _remote.generateStructuredJson(
        apiKey: apiKey,
        systemInstruction: PromptConstants.replySystemInstruction,
        userContent: PromptConstants.replyUserContent(emailBody),
        responseSchema: PromptConstants.replyResponseSchema,
      );

      final Object? outcome = json['outcome'];
      return ReplyOutcome.fromValue(outcome is String ? outcome : 'none');
    });
  }

  /// Loads the OpenAI API key, throwing an [AiException] (mapped to
  /// [AiFailure]) if it is missing so the UI can prompt the user to set it.
  Future<String> _requireApiKey() async {
    final Result<String> result = await _settings.getGeminiApiKey();
    return result.fold(
      (_) => throw const AiException(
        'Unable to read the OpenAI API key.',
      ),
      (String key) {
        if (key.trim().isEmpty) {
          throw const AiException(
            'OpenAI API key is not configured. Add it in Settings.',
          );
        }
        return key.trim();
      },
    );
  }
}
