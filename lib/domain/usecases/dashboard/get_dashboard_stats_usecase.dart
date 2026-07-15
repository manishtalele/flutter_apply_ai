import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_apply_ai/core/errors/failures.dart';
import 'package:flutter_apply_ai/core/utils/typedefs.dart';
import 'package:flutter_apply_ai/domain/entities/dashboard_stats.dart';
import 'package:flutter_apply_ai/domain/entities/enums/application_status.dart';
import 'package:flutter_apply_ai/domain/repositories/application_repository.dart';
import 'package:flutter_apply_ai/domain/usecases/usecase.dart';

/// Computes [DashboardStats] from the applications table. The reference time
/// [now] is passed in (not read from the clock) so the date-window boundaries
/// are deterministic and testable.
class GetDashboardStatsUseCase implements UseCase<DashboardStats, DateTime> {
  const GetDashboardStatsUseCase(this._repository);

  final ApplicationRepository _repository;

  @override
  ResultFuture<DashboardStats> call(DateTime now) async {
    final DateTime todayStart = DateTime(now.year, now.month, now.day);
    final DateTime weekStart =
        todayStart.subtract(Duration(days: now.weekday - 1));
    final DateTime monthStart = DateTime(now.year, now.month);

    final List<Either<Failure, int>> results = await Future.wait(
      <ResultFuture<int>>[
        _repository.countAll(),
        _repository.countAppliedSince(todayStart),
        _repository.countAppliedSince(weekStart),
        _repository.countAppliedSince(monthStart),
        _repository.countByStatus(ApplicationStatus.interview),
        _repository.countByStatus(ApplicationStatus.selected),
        _repository.countByStatus(ApplicationStatus.rejected),
        _repository.countByStatus(ApplicationStatus.noReply),
      ],
    );

    final Either<Failure, int>? firstFailure =
        results.firstWhereOrNull((Either<Failure, int> e) => e.isLeft());
    if (firstFailure != null) {
      return Left<Failure, DashboardStats>(
        firstFailure.swap().getOrElse(
              () => const UnknownFailure('Failed to compute stats.'),
            ),
      );
    }

    final List<int> counts =
        results.map((Either<Failure, int> e) => e.getOrElse(() => 0)).toList();

    final int interviews = counts[4];
    final int selected = counts[5];
    final int rejected = counts[6];

    return Right<Failure, DashboardStats>(
      DashboardStats(
        totalApplied: counts[0],
        appliedToday: counts[1],
        appliedThisWeek: counts[2],
        appliedThisMonth: counts[3],
        interviews: interviews,
        selected: selected,
        rejected: rejected,
        noReply: counts[7],
        replies: interviews + selected + rejected,
      ),
    );
  }
}
