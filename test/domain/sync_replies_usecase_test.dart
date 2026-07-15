import 'package:dartz/dartz.dart' show Right;
import 'package:flutter_apply_ai/core/errors/failures.dart';
import 'package:flutter_apply_ai/domain/entities/application.dart';
import 'package:flutter_apply_ai/domain/entities/enums/application_status.dart';
import 'package:flutter_apply_ai/domain/entities/enums/reply_outcome.dart';
import 'package:flutter_apply_ai/domain/repositories/ai_repository.dart';
import 'package:flutter_apply_ai/domain/repositories/application_repository.dart';
import 'package:flutter_apply_ai/domain/repositories/gmail_repository.dart';
import 'package:flutter_apply_ai/domain/usecases/gmail/sync_replies_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGmail extends Mock implements GmailRepository {}

class _MockAi extends Mock implements AiRepository {}

class _MockApps extends Mock implements ApplicationRepository {}

Application _app({
  required int id,
  required ApplicationStatus status,
  String? threadId,
}) {
  final DateTime t = DateTime.fromMillisecondsSinceEpoch(0);
  return Application(
    id: id,
    company: 'Acme',
    email: 'jobs@acme.com',
    role: 'Dev',
    location: 'Remote',
    subject: 'S',
    emailBody: 'B',
    matchScore: 80,
    status: status,
    resumeName: 'Default',
    gmailThreadId: threadId,
    appliedAt: t,
    updatedAt: t,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_app(id: 0, status: ApplicationStatus.applied));
  });

  late _MockGmail gmail;
  late _MockAi ai;
  late _MockApps apps;
  late SyncRepliesUseCase useCase;

  setUp(() {
    gmail = _MockGmail();
    ai = _MockAi();
    apps = _MockApps();
    useCase = SyncRepliesUseCase(
      gmailRepository: gmail,
      aiRepository: ai,
      applicationRepository: apps,
    );
  });

  test('updates a replied application and skips terminal/no-thread ones',
      () async {
    final Application applied =
        _app(id: 1, status: ApplicationStatus.applied, threadId: 't1');
    final Application terminal =
        _app(id: 2, status: ApplicationStatus.selected, threadId: 't2');
    final Application noThread =
        _app(id: 3, status: ApplicationStatus.applied);

    when(apps.getApplications).thenAnswer(
      (_) async => Right<Failure, List<Application>>(
        <Application>[applied, terminal, noThread],
      ),
    );
    when(() => gmail.fetchLatestIncomingReply('t1')).thenAnswer(
      (_) async => const Right<Failure, String?>('We would like to interview you.'),
    );
    when(() => ai.classifyReply(any())).thenAnswer(
      (_) async => const Right<Failure, ReplyOutcome>(ReplyOutcome.interview),
    );
    when(() => apps.update(any())).thenAnswer(
      (_) async => const Right<Failure, void>(null),
    );

    final result = await useCase(DateTime.fromMillisecondsSinceEpoch(1000));

    expect(result.getOrElse(() => -1), 1);

    final Application updated =
        verify(() => apps.update(captureAny())).captured.single as Application;
    expect(updated.id, 1);
    expect(updated.status, ApplicationStatus.interview);

    // Terminal and no-thread applications never trigger a Gmail fetch.
    verifyNever(() => gmail.fetchLatestIncomingReply('t2'));
  });

  test('no update when there is no reply', () async {
    final Application applied =
        _app(id: 1, status: ApplicationStatus.applied, threadId: 't1');
    when(apps.getApplications).thenAnswer(
      (_) async => Right<Failure, List<Application>>(<Application>[applied]),
    );
    when(() => gmail.fetchLatestIncomingReply('t1'))
        .thenAnswer((_) async => const Right<Failure, String?>(null));

    final result = await useCase(DateTime.fromMillisecondsSinceEpoch(1000));

    expect(result.getOrElse(() => -1), 0);
    verifyNever(() => apps.update(any()));
  });
}
