import 'package:flutter_apply_ai/core/utils/typedefs.dart';
import 'package:flutter_apply_ai/domain/entities/application.dart';
import 'package:flutter_apply_ai/domain/entities/enums/application_status.dart';

/// Persistence contract for job applications. Implemented by the Data layer
/// over SQLite; consumed by use cases.
abstract interface class ApplicationRepository {
  /// Inserts [application] and returns it with its assigned id populated.
  ResultFuture<Application> save(Application application);

  ResultFuture<void> update(Application application);

  ResultFuture<void> delete(int id);

  ResultFuture<Application?> getById(int id);

  /// Newest-first list, optionally filtered by [search] and/or [status] and
  /// paginated by [limit]/[offset].
  ResultFuture<List<Application>> getApplications({
    String? search,
    ApplicationStatus? status,
    int? limit,
    int? offset,
  });

  /// All applications previously sent to [email] — powers duplicate detection.
  ResultFuture<List<Application>> findByEmail(String email);

  ResultFuture<int> countAll();

  ResultFuture<int> countAppliedSince(DateTime since);

  ResultFuture<int> countByStatus(ApplicationStatus status);
}
