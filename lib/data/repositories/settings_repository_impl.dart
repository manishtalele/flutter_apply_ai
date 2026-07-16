import 'package:flutter_apply_ai/core/constants/storage_keys.dart';
import 'package:flutter_apply_ai/core/utils/app_logger.dart';
import 'package:flutter_apply_ai/core/utils/typedefs.dart';
import 'package:flutter_apply_ai/data/datasources/local/secure_storage_datasource.dart';
import 'package:flutter_apply_ai/data/datasources/local/settings_local_datasource.dart';
import 'package:flutter_apply_ai/data/models/app_settings_model.dart';
import 'package:flutter_apply_ai/data/repositories/repository_error_mapper.dart';
import 'package:flutter_apply_ai/domain/entities/app_settings.dart';
import 'package:flutter_apply_ai/domain/repositories/settings_repository.dart';

/// [SettingsRepository] over SharedPreferences (non-secret bundle) + secure
/// storage (OpenAI API key). Keeps the secret out of preferences by loading
/// it from secure storage only when assembling the full [AppSettings].
class SettingsRepositoryImpl
    with RepositoryErrorMapper
    implements SettingsRepository {
  SettingsRepositoryImpl({
    required SettingsLocalDataSource settingsDataSource,
    required SecureStorageDataSource secureDataSource,
    required AppLogger logger,
  })  : _settings = settingsDataSource,
        _secure = secureDataSource,
        _logger = logger;

  final SettingsLocalDataSource _settings;
  final SecureStorageDataSource _secure;
  final AppLogger _logger;

  @override
  AppLogger get logger => _logger;

  @override
  ResultFuture<AppSettings> getSettings() {
    return guard<AppSettings>(() async {
      final String apiKey =
          await _secure.read(StorageKeys.secureOpenAiApiKey) ?? '';
      final Map<String, dynamic> bundle =
          await _settings.readSettingsBundle();
      return AppSettingsModel.fromPrefsJson(bundle, openAiApiKey: apiKey);
    });
  }

  @override
  ResultVoid saveSettings(AppSettings settings) {
    return guard<void>(() async {
      final AppSettingsModel model = AppSettingsModel.fromEntity(settings);
      await _settings.writeSettingsBundle(model.toPrefsJson());
    });
  }

  @override
  ResultFuture<String> getOpenAiApiKey() {
    return guard<String>(
      () async => await _secure.read(StorageKeys.secureOpenAiApiKey) ?? '',
    );
  }

  @override
  ResultVoid saveOpenAiApiKey(String apiKey) {
    return guard<void>(
      () => _secure.write(StorageKeys.secureOpenAiApiKey, apiKey.trim()),
    );
  }

  @override
  ResultVoid clearOpenAiApiKey() {
    return guard<void>(() => _secure.delete(StorageKeys.secureOpenAiApiKey));
  }
}
