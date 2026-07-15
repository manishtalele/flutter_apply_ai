import 'package:flutter_apply_ai/core/utils/csv_exporter.dart';
import 'package:flutter_apply_ai/core/utils/date_formatter.dart';
import 'package:flutter_apply_ai/core/utils/typedefs.dart';
import 'package:flutter_apply_ai/domain/entities/application.dart';
import 'package:flutter_apply_ai/domain/repositories/application_repository.dart';
import 'package:flutter_apply_ai/domain/usecases/usecase.dart';

/// Fetches all applications and serializes them to CSV text.
class ExportApplicationsUseCase implements UseCase<String, NoParams> {
  const ExportApplicationsUseCase(this._repository);

  final ApplicationRepository _repository;

  static const List<String> _headers = <String>[
    'Company',
    'Role',
    'Email',
    'Location',
    'Match Score',
    'Status',
    'Resume',
    'Applied At',
  ];

  @override
  ResultFuture<String> call(NoParams params) async {
    final result = await _repository.getApplications();
    return result.map((List<Application> applications) {
      final List<List<String>> rows = applications
          .map(
            (Application app) => <String>[
              app.company,
              app.role,
              app.email,
              app.location,
              app.matchScore.toString(),
              app.status.label,
              app.resumeName,
              DateFormatter.iso(app.appliedAt),
            ],
          )
          .toList(growable: false);
      return CsvExporter.build(_headers, rows);
    });
  }
}
