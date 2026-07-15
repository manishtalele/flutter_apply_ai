import 'package:dartz/dartz.dart';
import 'package:flutter_apply_ai/core/errors/failures.dart';
import 'package:flutter_apply_ai/core/utils/typedefs.dart';
import 'package:flutter_apply_ai/domain/entities/application.dart';
import 'package:flutter_apply_ai/domain/entities/enums/application_status.dart';
import 'package:flutter_apply_ai/domain/entities/enums/reply_outcome.dart';
import 'package:flutter_apply_ai/domain/repositories/ai_repository.dart';
import 'package:flutter_apply_ai/domain/repositories/application_repository.dart';
import 'package:flutter_apply_ai/domain/repositories/gmail_repository.dart';
import 'package:flutter_apply_ai/domain/usecases/usecase.dart';

/// Scans non-terminal applications, reads the latest incoming Gmail reply for
/// each, classifies it with the AI, and updates the stored status. Returns the
/// number of applications whose status changed.
class SyncRepliesUseCase implements UseCase<int, DateTime> {
  const SyncRepliesUseCase({
    required GmailRepository gmailRepository,
    required AiRepository aiRepository,
    required ApplicationRepository applicationRepository,
  })  : _gmail = gmailRepository,
        _ai = aiRepository,
        _applications = applicationRepository;

  final GmailRepository _gmail;
  final AiRepository _ai;
  final ApplicationRepository _applications;

  /// [now] is passed in for a deterministic `updatedAt` timestamp.
  @override
  ResultFuture<int> call(DateTime now) async {
    final Either<Failure, List<Application>> appsResult =
        await _applications.getApplications();
    if (appsResult.isLeft()) {
      return Left<Failure, int>(
        appsResult.swap().getOrElse(
              () => const UnknownFailure('Failed to load applications.'),
            ),
      );
    }

    final List<Application> applications =
        appsResult.getOrElse(() => <Application>[]);
    int updatedCount = 0;

    for (final Application application in applications) {
      final int? updated = await _syncOne(application, now);
      if (updated != null) {
        updatedCount += updated;
      }
    }
    return Right<Failure, int>(updatedCount);
  }

  /// Returns 1 if the application's status changed, 0 otherwise, or `null` if
  /// it was skipped (terminal status / no thread / no reply / error).
  Future<int?> _syncOne(Application application, DateTime now) async {
    final String? threadId = application.gmailThreadId;
    if (threadId == null || threadId.isEmpty) {
      return null;
    }
    // Terminal statuses are never re-evaluated.
    if (application.status == ApplicationStatus.selected ||
        application.status == ApplicationStatus.rejected) {
      return null;
    }

    final Either<Failure, String?> replyResult =
        await _gmail.fetchLatestIncomingReply(threadId);
    final String? body = replyResult.getOrElse(() => null);
    if (body == null || body.trim().isEmpty) {
      return null;
    }

    final Either<Failure, ReplyOutcome> outcomeResult =
        await _ai.classifyReply(body);
    final ReplyOutcome outcome =
        outcomeResult.getOrElse(() => ReplyOutcome.none);
    final ApplicationStatus? newStatus = outcome.toStatus();

    if (newStatus == null || newStatus == application.status) {
      return null;
    }

    final Either<Failure, void> updateResult = await _applications.update(
      application.copyWith(status: newStatus, updatedAt: now),
    );
    return updateResult.isRight() ? 1 : 0;
  }
}
