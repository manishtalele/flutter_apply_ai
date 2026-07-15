import 'package:dartz/dartz.dart' show Right;
import 'package:flutter_apply_ai/core/errors/failures.dart';
import 'package:flutter_apply_ai/core/utils/csv_exporter.dart';
import 'package:flutter_apply_ai/domain/entities/application.dart';
import 'package:flutter_apply_ai/domain/entities/enums/application_status.dart';
import 'package:flutter_apply_ai/domain/repositories/application_repository.dart';
import 'package:flutter_apply_ai/domain/usecases/application/export_applications_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements ApplicationRepository {}

void main() {
  group('CsvExporter', () {
    test('escapes fields containing commas, quotes, and newlines', () {
      final String csv = CsvExporter.build(
        <String>['a', 'b'],
        <List<String>>[
          <String>['plain', 'has,comma'],
          <String>['has"quote', 'line1\nline2'],
        ],
      );
      expect(csv, contains('a,b'));
      expect(csv, contains('plain,"has,comma"'));
      expect(csv, contains('"has""quote"'));
      expect(csv, contains('"line1\nline2"'));
    });
  });

  group('ExportApplicationsUseCase', () {
    test('produces a CSV with a header row and one row per application',
        () async {
      final _MockRepo repo = _MockRepo();
      final Application app = Application(
        id: 1,
        company: 'Acme',
        email: 'jobs@acme.com',
        role: 'Flutter Developer',
        location: 'Remote',
        subject: 'Application',
        emailBody: 'Body',
        matchScore: 90,
        status: ApplicationStatus.interview,
        resumeName: 'Flutter Resume',
        appliedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
      );
      when(repo.getApplications).thenAnswer(
        (_) async => Right<Failure, List<Application>>(<Application>[app]),
      );

      final result =
          await ExportApplicationsUseCase(repo).call(const NoParams());

      expect(result.isRight(), isTrue);
      final String csv = result.getOrElse(() => '');
      expect(csv, contains('Company,Role,Email'));
      expect(csv, contains('Acme'));
      expect(csv, contains('Flutter Developer'));
      expect(csv, contains('Interview'));
    });
  });
}
