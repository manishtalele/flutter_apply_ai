import 'package:flutter_apply_ai/core/utils/typedefs.dart';
import 'package:flutter_apply_ai/domain/repositories/settings_repository.dart';
import 'package:flutter_apply_ai/domain/usecases/usecase.dart';

/// Persists the Gemini API key to secure storage.
class SaveGeminiApiKeyUseCase implements UseCase<void, String> {
  const SaveGeminiApiKeyUseCase(this._repository);

  final SettingsRepository _repository;

  @override
  ResultVoid call(String apiKey) => _repository.saveGeminiApiKey(apiKey);
}
