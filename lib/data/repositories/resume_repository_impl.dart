import 'package:collection/collection.dart';
import 'package:flutter_apply_ai/core/utils/app_logger.dart';
import 'package:flutter_apply_ai/core/utils/typedefs.dart';
import 'package:flutter_apply_ai/data/datasources/local/settings_local_datasource.dart';
import 'package:flutter_apply_ai/data/models/resume_profile_model.dart';
import 'package:flutter_apply_ai/data/repositories/repository_error_mapper.dart';
import 'package:flutter_apply_ai/domain/entities/resume_profile.dart';
import 'package:flutter_apply_ai/domain/repositories/resume_repository.dart';

/// [ResumeRepository] persisting resume profiles as a JSON list in
/// SharedPreferences (via [SettingsLocalDataSource]). Enforces the "exactly
/// one default" invariant on every mutation.
class ResumeRepositoryImpl
    with RepositoryErrorMapper
    implements ResumeRepository {
  ResumeRepositoryImpl({
    required SettingsLocalDataSource settingsDataSource,
    required AppLogger logger,
  })  : _settings = settingsDataSource,
        _logger = logger;

  final SettingsLocalDataSource _settings;
  final AppLogger _logger;

  @override
  AppLogger get logger => _logger;

  @override
  ResultFuture<List<ResumeProfile>> getResumes() {
    return guard<List<ResumeProfile>>(_load);
  }

  @override
  ResultFuture<ResumeProfile> addResume({
    required String label,
    required String filePath,
    bool makeDefault = false,
  }) {
    return guard<ResumeProfile>(() async {
      final List<ResumeProfileModel> models = await _load();
      final bool shouldBeDefault = makeDefault || models.isEmpty;
      final DateTime now = DateTime.now();

      final ResumeProfileModel created = ResumeProfileModel(
        id: now.microsecondsSinceEpoch.toString(),
        label: label.trim(),
        filePath: filePath,
        isDefault: shouldBeDefault,
        createdAt: now,
      );

      final List<ResumeProfileModel> next = <ResumeProfileModel>[
        if (shouldBeDefault)
          ...models.map(
            (ResumeProfileModel m) =>
                ResumeProfileModel.fromEntity(m.copyWith(isDefault: false)),
          )
        else
          ...models,
        created,
      ];

      await _persist(next);
      return created;
    });
  }

  @override
  ResultVoid deleteResume(String id) {
    return guard<void>(() async {
      final List<ResumeProfileModel> models = await _load();
      final bool removedWasDefault =
          models.any((ResumeProfileModel m) => m.id == id && m.isDefault);
      final List<ResumeProfileModel> remaining = models
          .where((ResumeProfileModel m) => m.id != id)
          .toList();

      // Preserve the "one default exists" invariant by promoting the first
      // remaining resume if the deleted one was the default.
      if (removedWasDefault &&
          remaining.isNotEmpty &&
          !remaining.any((ResumeProfileModel m) => m.isDefault)) {
        remaining[0] = ResumeProfileModel.fromEntity(
          remaining.first.copyWith(isDefault: true),
        );
      }

      await _persist(remaining);
    });
  }

  @override
  ResultVoid setDefault(String id) {
    return guard<void>(() async {
      final List<ResumeProfileModel> models = await _load();
      final List<ResumeProfileModel> next = models
          .map(
            (ResumeProfileModel m) =>
                ResumeProfileModel.fromEntity(m.copyWith(isDefault: m.id == id)),
          )
          .toList();
      await _persist(next);
    });
  }

  @override
  ResultFuture<ResumeProfile?> getDefault() {
    return guard<ResumeProfile?>(() async {
      final List<ResumeProfileModel> models = await _load();
      return models.firstWhereOrNull((ResumeProfileModel m) => m.isDefault);
    });
  }

  Future<List<ResumeProfileModel>> _load() async {
    final List<Map<String, dynamic>> raw = await _settings.readResumes();
    return raw.map(ResumeProfileModel.fromJson).toList();
  }

  Future<void> _persist(List<ResumeProfileModel> models) async {
    await _settings.writeResumes(
      models.map((ResumeProfileModel m) => m.toJson()).toList(),
    );
  }
}
