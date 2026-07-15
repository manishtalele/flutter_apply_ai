import 'package:flutter_apply_ai/core/errors/exceptions.dart';
import 'package:flutter_apply_ai/core/errors/failures.dart';
import 'package:flutter_apply_ai/core/utils/app_logger.dart';
import 'package:flutter_apply_ai/data/datasources/local/application_local_datasource.dart';
import 'package:flutter_apply_ai/data/models/application_model.dart';
import 'package:flutter_apply_ai/data/repositories/application_repository_impl.dart';
import 'package:flutter_apply_ai/domain/entities/application.dart';
import 'package:flutter_apply_ai/domain/entities/enums/application_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockLocal extends Mock implements ApplicationLocalDataSource {}

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

Application _application() {
  final DateTime epoch = DateTime.fromMillisecondsSinceEpoch(0);
  return Application(
    company: 'Acme',
    email: 'jobs@acme.com',
    role: 'Flutter Developer',
    location: 'Remote',
    subject: 'Application',
    emailBody: 'Body',
    matchScore: 80,
    status: ApplicationStatus.applied,
    resumeName: 'Default',
    appliedAt: epoch,
    updatedAt: epoch,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(ApplicationModel.fromEntity(_application()));
  });

  late _MockLocal local;
  late ApplicationRepositoryImpl repository;

  setUp(() {
    local = _MockLocal();
    repository = ApplicationRepositoryImpl(
      localDataSource: local,
      logger: const _SilentLogger(),
    );
  });

  test('save returns Right with the id populated', () async {
    when(() => local.insert(any())).thenAnswer((_) async => 7);

    final result = await repository.save(_application());

    expect(result.isRight(), isTrue);
    result.fold(
      (_) => fail('expected Right'),
      (Application app) => expect(app.id, 7),
    );
  });

  test('maps LocalDatabaseException to DatabaseFailure', () async {
    when(() => local.insert(any()))
        .thenThrow(const LocalDatabaseException('boom'));

    final result = await repository.save(_application());

    expect(result.isLeft(), isTrue);
    result.fold(
      (Failure failure) => expect(failure, isA<DatabaseFailure>()),
      (_) => fail('expected Left'),
    );
  });

  test('maps NotFoundException to NotFoundFailure on update', () async {
    when(() => local.update(any()))
        .thenThrow(const NotFoundException('missing'));

    final result = await repository.update(_application().copyWith(id: 5));

    result.fold(
      (Failure failure) => expect(failure, isA<NotFoundFailure>()),
      (_) => fail('expected Left'),
    );
  });

  test('maps an unexpected error to UnknownFailure', () async {
    when(() => local.insert(any())).thenThrow(Exception('weird'));

    final result = await repository.save(_application());

    result.fold(
      (Failure failure) => expect(failure, isA<UnknownFailure>()),
      (_) => fail('expected Left'),
    );
  });
}
