import 'package:flutter_apply_ai/core/errors/exceptions.dart';
import 'package:flutter_apply_ai/core/utils/app_logger.dart';
import 'package:flutter_apply_ai/data/datasources/local/app_database.dart';
import 'package:flutter_apply_ai/data/datasources/local/application_local_datasource.dart';
import 'package:flutter_apply_ai/data/models/application_model.dart';
import 'package:flutter_apply_ai/domain/entities/enums/application_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// No-op logger so tests stay quiet.
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

ApplicationModel _model({
  int? id,
  String email = 'jobs@acme.com',
  ApplicationStatus status = ApplicationStatus.applied,
  DateTime? appliedAt,
}) {
  final DateTime when =
      appliedAt ?? DateTime.fromMillisecondsSinceEpoch(1700000000000);
  return ApplicationModel(
    id: id,
    company: 'Acme',
    email: email,
    role: 'Flutter Developer',
    location: 'Remote',
    subject: 'Application',
    emailBody: 'Body',
    matchScore: 80,
    status: status,
    resumeName: 'Default',
    appliedAt: when,
    updatedAt: when,
  );
}

void main() {
  sqfliteFfiInit();

  late AppDatabase database;
  late ApplicationLocalDataSource dao;

  setUp(() {
    database = AppDatabase(
      logger: const _SilentLogger(),
      factory: databaseFactoryFfi,
      pathOverride: inMemoryDatabasePath,
    );
    dao = ApplicationLocalDataSourceImpl(
      database: database,
      logger: const _SilentLogger(),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('insert returns a positive id and getById retrieves the row', () async {
    final int id = await dao.insert(_model());
    expect(id, greaterThan(0));

    final ApplicationModel? fetched = await dao.getById(id);
    expect(fetched, isNotNull);
    expect(fetched!.company, 'Acme');
    expect(fetched.status, ApplicationStatus.applied);
  });

  test('findByEmail matches case-insensitively', () async {
    await dao.insert(_model(email: 'Jobs@Acme.com'));
    final List<ApplicationModel> matches =
        await dao.findByEmail('jobs@acme.com');
    expect(matches, hasLength(1));
  });

  test('getAll supports search and status filtering', () async {
    await dao.insert(_model(email: 'a@x.com'));
    await dao.insert(
      _model(email: 'b@x.com', status: ApplicationStatus.interview),
    );

    expect(await dao.getAll(), hasLength(2));
    expect(
      await dao.getAll(status: ApplicationStatus.interview),
      hasLength(1),
    );
    expect(await dao.getAll(search: 'Flutter'), hasLength(2));
    expect(await dao.getAll(search: 'Python'), isEmpty);
  });

  test('count aggregates are correct', () async {
    final DateTime old = DateTime.fromMillisecondsSinceEpoch(1000);
    final DateTime recent = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    await dao.insert(
      _model(email: 'a@x.com', status: ApplicationStatus.rejected, appliedAt: old),
    );
    await dao.insert(
      _model(
        email: 'b@x.com',
        status: ApplicationStatus.interview,
        appliedAt: recent,
      ),
    );

    expect(await dao.countAll(), 2);
    expect(await dao.countByStatus(ApplicationStatus.interview), 1);
    expect(
      await dao.countAppliedSince(DateTime.fromMillisecondsSinceEpoch(1000000)),
      1,
    );
  });

  test('update mutates the row; deleteById removes it', () async {
    final int id = await dao.insert(_model());
    final ApplicationModel fetched = (await dao.getById(id))!;

    await dao.update(
      ApplicationModel.fromEntity(
        fetched.copyWith(status: ApplicationStatus.selected),
      ),
    );
    expect((await dao.getById(id))!.status, ApplicationStatus.selected);

    await dao.deleteById(id);
    expect(await dao.getById(id), isNull);
  });

  test('update throws NotFoundException for a missing row', () async {
    expect(
      () => dao.update(_model(id: 999999)),
      throwsA(isA<NotFoundException>()),
    );
  });
}
