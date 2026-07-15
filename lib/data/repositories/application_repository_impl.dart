import 'package:flutter_apply_ai/core/utils/app_logger.dart';
import 'package:flutter_apply_ai/core/utils/typedefs.dart';
import 'package:flutter_apply_ai/data/datasources/local/application_local_datasource.dart';
import 'package:flutter_apply_ai/data/models/application_model.dart';
import 'package:flutter_apply_ai/data/repositories/repository_error_mapper.dart';
import 'package:flutter_apply_ai/domain/entities/application.dart';
import 'package:flutter_apply_ai/domain/entities/enums/application_status.dart';
import 'package:flutter_apply_ai/domain/repositories/application_repository.dart';

/// SQLite-backed [ApplicationRepository]. Delegates persistence to
/// [ApplicationLocalDataSource] and maps exceptions to failures via
/// [RepositoryErrorMapper].
class ApplicationRepositoryImpl
    with RepositoryErrorMapper
    implements ApplicationRepository {
  ApplicationRepositoryImpl({
    required ApplicationLocalDataSource localDataSource,
    required AppLogger logger,
  })  : _local = localDataSource,
        _logger = logger;

  final ApplicationLocalDataSource _local;
  final AppLogger _logger;

  @override
  AppLogger get logger => _logger;

  @override
  ResultFuture<Application> save(Application application) {
    return guard<Application>(() async {
      final int id = await _local.insert(
        ApplicationModel.fromEntity(application),
      );
      return application.copyWith(id: id);
    });
  }

  @override
  ResultVoid update(Application application) {
    return guard<void>(
      () => _local.update(ApplicationModel.fromEntity(application)),
    );
  }

  @override
  ResultVoid delete(int id) {
    return guard<void>(() => _local.deleteById(id));
  }

  @override
  ResultFuture<Application?> getById(int id) {
    return guard<Application?>(() => _local.getById(id));
  }

  @override
  ResultFuture<List<Application>> getApplications({
    String? search,
    ApplicationStatus? status,
    int? limit,
    int? offset,
  }) {
    return guard<List<Application>>(
      () => _local.getAll(
        search: search,
        status: status,
        limit: limit,
        offset: offset,
      ),
    );
  }

  @override
  ResultFuture<List<Application>> findByEmail(String email) {
    return guard<List<Application>>(() => _local.findByEmail(email));
  }

  @override
  ResultFuture<int> countAll() {
    return guard<int>(_local.countAll);
  }

  @override
  ResultFuture<int> countAppliedSince(DateTime since) {
    return guard<int>(() => _local.countAppliedSince(since));
  }

  @override
  ResultFuture<int> countByStatus(ApplicationStatus status) {
    return guard<int>(() => _local.countByStatus(status));
  }
}
