import 'package:flutter_apply_ai/core/utils/typedefs.dart';
import 'package:flutter_apply_ai/domain/entities/app_settings.dart';
import 'package:flutter_apply_ai/domain/repositories/settings_repository.dart';
import 'package:flutter_apply_ai/domain/usecases/usecase.dart';

/// Persists the non-secret settings bundle (theme, default resume, sender
/// name, Gmail account label).
class UpdateSettingsUseCase implements UseCase<void, AppSettings> {
  const UpdateSettingsUseCase(this._repository);

  final SettingsRepository _repository;

  @override
  ResultVoid call(AppSettings settings) => _repository.saveSettings(settings);
}
