import 'package:dartz/dartz.dart' show Right;
import 'package:flutter_apply_ai/core/errors/failures.dart';
import 'package:flutter_apply_ai/domain/entities/dashboard_stats.dart';
import 'package:flutter_apply_ai/domain/entities/enums/application_status.dart';
import 'package:flutter_apply_ai/domain/repositories/application_repository.dart';
import 'package:flutter_apply_ai/domain/usecases/dashboard/get_dashboard_stats_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements ApplicationRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime.fromMillisecondsSinceEpoch(0));
  });

  test('aggregates counts and derives replies as interview+selected+rejected',
      () async {
    final _MockRepo repo = _MockRepo();

    when(repo.countAll)
        .thenAnswer((_) async => const Right<Failure, int>(10));
    when(() => repo.countAppliedSince(any()))
        .thenAnswer((_) async => const Right<Failure, int>(3));
    when(() => repo.countByStatus(ApplicationStatus.interview))
        .thenAnswer((_) async => const Right<Failure, int>(2));
    when(() => repo.countByStatus(ApplicationStatus.selected))
        .thenAnswer((_) async => const Right<Failure, int>(1));
    when(() => repo.countByStatus(ApplicationStatus.rejected))
        .thenAnswer((_) async => const Right<Failure, int>(4));
    when(() => repo.countByStatus(ApplicationStatus.noReply))
        .thenAnswer((_) async => const Right<Failure, int>(3));

    final result =
        await GetDashboardStatsUseCase(repo).call(DateTime(2026, 7, 15));

    final DashboardStats stats =
        result.getOrElse(() => DashboardStats.empty);
    expect(stats.totalApplied, 10);
    expect(stats.appliedToday, 3);
    expect(stats.appliedThisWeek, 3);
    expect(stats.appliedThisMonth, 3);
    expect(stats.interviews, 2);
    expect(stats.selected, 1);
    expect(stats.rejected, 4);
    expect(stats.noReply, 3);
    expect(stats.replies, 7);
    expect(stats.replyRate, closeTo(0.7, 0.0001));
  });
}
