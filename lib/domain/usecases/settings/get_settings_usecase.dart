import 'package:flutter_apply_ai/core/utils/typedefs.dart';
import 'package:flutter_apply_ai/domain/entities/app_settings.dart';
import 'package:flutter_apply_ai/domain/repositories/settings_repository.dart';
import 'package:flutter_apply_ai/domain/usecases/usecase.dart';

/// Loads the current application settings (non-secret bundle + API key).
class GetSettingsUseCase implements UseCase<AppSettings, NoParams> {
  const GetSettingsUseCase(this._repository);

  final SettingsRepository _repository;

  @override
  ResultFuture<AppSettings> call(NoParams params) => _repository.getSettings();
}
