import 'package:flutter_apply_ai/core/utils/typedefs.dart';
import 'package:flutter_apply_ai/domain/repositories/settings_repository.dart';
import 'package:flutter_apply_ai/domain/usecases/usecase.dart';

/// Persists the OpenAI API key to secure storage.
class SaveOpenAiApiKeyUseCase implements UseCase<void, String> {
  const SaveOpenAiApiKeyUseCase(this._repository);

  final SettingsRepository _repository;

  @override
  ResultVoid call(String apiKey) => _repository.saveOpenAiApiKey(apiKey);
}
