import 'package:flutter_apply_ai/core/utils/app_logger.dart';
import 'package:flutter_apply_ai/data/datasources/local/app_database.dart';
import 'package:flutter_apply_ai/data/datasources/local/application_local_datasource.dart';
import 'package:flutter_apply_ai/data/repositories/application_repository_impl.dart';
import 'package:flutter_apply_ai/domain/entities/application.dart';
import 'package:flutter_apply_ai/domain/entities/enums/application_status.dart';
import 'package:flutter_apply_ai/domain/repositories/application_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// End-to-end persistence test exercising the REAL repository over the REAL
/// DAO over a REAL (in-memory FFI) SQLite database — no mocks. Verifies the
/// full stack the app relies on for save/query/update/delete/aggregate.
class _SilentLogger implements AppLogger {
  const _SilentLogger();

  @override
  void d(String message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void i(String message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void w(String message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void e(String message, [Object? error, StackTrace? stackTrace]) {}
}

Application _application({
  String company = 'Acme',
  String email = 'jobs@acme.com',
  ApplicationStatus status = ApplicationStatus.applied,
}) {
  final DateTime now = DateTime.fromMillisecondsSinceEpoch(1700000000000);
  return Application(
    company: company,
    email: email,
    role: 'Flutter Developer',
    location: 'Remote',
    subject: 'Application',
    emailBody: '<p>Body</p>',
    matchScore: 88,
    status: status,
    resumeName: 'Default',
    appliedAt: now,
    updatedAt: now,
  );
}

void main() {
  sqfliteFfiInit();

  late AppDatabase database;
  late ApplicationRepository repository;

  setUp(() {
    database = AppDatabase(
      logger: const _SilentLogger(),
      factory: databaseFactoryFfi,
      pathOverride: inMemoryDatabasePath,
    );
    final ApplicationLocalDataSource dao = ApplicationLocalDataSourceImpl(
      database: database,
      logger: const _SilentLogger(),
    );
    repository = ApplicationRepositoryImpl(
      localDataSource: dao,
      logger: const _SilentLogger(),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('save → query → update → delete round-trip through the repository',
      () async {
    // Save.
    final saveResult = await repository.save(_application());
    final Application saved = saveResult.getOrElse(() => fail('save failed'));
    expect(saved.id, isNotNull);

    // Duplicate detection (case-insensitive).
    final dupResult = await repository.findByEmail('JOBS@ACME.COM');
    expect(
      dupResult.getOrElse(() => <Application>[]),
      hasLength(1),
    );

    // Query all.
    final allResult = await repository.getApplications();
    expect(allResult.getOrElse(() => <Application>[]), hasLength(1));

    // Update status.
    final updateResult = await repository.update(
      saved.copyWith(status: ApplicationStatus.interview),
    );
    expect(updateResult.isRight(), isTrue);

    final byIdResult = await repository.getById(saved.id!);
    final Application? fetched = byIdResult.getOrElse(() => null);
    expect(fetched?.status, ApplicationStatus.interview);

    // Aggregates.
    final countAll = await repository.countAll();
    expect(countAll.getOrElse(() => 0), 1);
    final interviewCount =
        await repository.countByStatus(ApplicationStatus.interview);
    expect(interviewCount.getOrElse(() => 0), 1);

    // Delete.
    final deleteResult = await repository.delete(saved.id!);
    expect(deleteResult.isRight(), isTrue);

    final afterDelete = await repository.getApplications();
    expect(afterDelete.getOrElse(() => <Application>[]), isEmpty);
  });

  test('search filters across company/role/email/location', () async {
    await repository.save(_application(email: 'a@x.com'));
    await repository.save(
      _application(company: 'Globex', email: 'b@y.com'),
    );

    final searchGlobex = await repository.getApplications(search: 'Globex');
    expect(searchGlobex.getOrElse(() => <Application>[]), hasLength(1));

    final searchRemote = await repository.getApplications(search: 'Remote');
    expect(searchRemote.getOrElse(() => <Application>[]), hasLength(2));

    final searchNone = await repository.getApplications(search: 'Nonexistent');
    expect(searchNone.getOrElse(() => <Application>[]), isEmpty);
  });

  test('two applications to the same email are both retained', () async {
    await repository.save(_application());
    await repository.save(_application());

    final dupResult = await repository.findByEmail('jobs@acme.com');
    expect(dupResult.getOrElse(() => <Application>[]), hasLength(2));
  });
}
