import 'package:dartz/dartz.dart' show Left, Right;
import 'package:flutter_apply_ai/core/errors/failures.dart';
import 'package:flutter_apply_ai/domain/entities/application.dart';
import 'package:flutter_apply_ai/domain/entities/email_draft.dart';
import 'package:flutter_apply_ai/domain/entities/enums/application_status.dart';
import 'package:flutter_apply_ai/domain/entities/job_posting.dart';
import 'package:flutter_apply_ai/domain/entities/resume_profile.dart';
import 'package:flutter_apply_ai/domain/entities/sent_email.dart';
import 'package:flutter_apply_ai/domain/repositories/application_repository.dart';
import 'package:flutter_apply_ai/domain/repositories/gmail_repository.dart';
import 'package:flutter_apply_ai/domain/usecases/application/send_application_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGmail extends Mock implements GmailRepository {}

class _MockApplications extends Mock implements ApplicationRepository {}

const JobPosting _posting = JobPosting(
  company: 'Acme',
  email: 'jobs@acme.com',
  role: 'Flutter Developer',
  location: 'Remote',
  experience: '3+ years',
  skills: <String>['Flutter'],
  subject: 'Application',
  emailBody: '<p>Hi</p>',
  matchScore: 90,
  shouldApply: true,
);

final ResumeProfile _resume = ResumeProfile(
  id: 'r1',
  label: 'Flutter Resume',
  filePath: '/tmp/resume.pdf',
  isDefault: true,
  createdAt: DateTime.fromMillisecondsSinceEpoch(0),
);

SendApplicationParams _params() => SendApplicationParams(
      posting: _posting,
      resume: _resume,
      senderName: 'Jane',
      appliedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
    );

void main() {
  setUpAll(() {
    registerFallbackValue(
      const EmailDraft(recipient: '', subject: '', htmlBody: ''),
    );
    registerFallbackValue(
      Application(
        company: '',
        email: '',
        role: '',
        location: '',
        subject: '',
        emailBody: '',
        matchScore: 0,
        status: ApplicationStatus.applied,
        resumeName: '',
        appliedAt: DateTime.fromMillisecondsSinceEpoch(0),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
      ),
    );
  });

  late _MockGmail gmail;
  late _MockApplications apps;
  late SendApplicationUseCase useCase;

  setUp(() {
    gmail = _MockGmail();
    apps = _MockApplications();
    useCase = SendApplicationUseCase(
      gmailRepository: gmail,
      applicationRepository: apps,
    );
  });

  test('sends then saves; the saved record carries Gmail ids and applied '
      'status', () async {
    when(() => gmail.sendEmail(any())).thenAnswer(
      (_) async => const Right<Failure, SentEmail>(
        SentEmail(messageId: 'msg-1', threadId: 'thr-1'),
      ),
    );
    when(() => apps.save(any())).thenAnswer(
      (Invocation i) async => Right<Failure, Application>(
        i.positionalArguments.first as Application,
      ),
    );

    final result = await useCase(_params());

    expect(result.isRight(), isTrue);
    final Application saved =
        verify(() => apps.save(captureAny())).captured.single as Application;
    expect(saved.gmailMessageId, 'msg-1');
    expect(saved.gmailThreadId, 'thr-1');
    expect(saved.status, ApplicationStatus.applied);
    expect(saved.resumeName, 'Flutter Resume');
    expect(saved.company, 'Acme');
  });

  test('composes the draft with the resume plus extra attachments', () async {
    when(() => gmail.sendEmail(any())).thenAnswer(
      (_) async => const Right<Failure, SentEmail>(
        SentEmail(messageId: 'm', threadId: 't'),
      ),
    );
    when(() => apps.save(any())).thenAnswer(
      (Invocation i) async => Right<Failure, Application>(
        i.positionalArguments.first as Application,
      ),
    );

    await useCase(
      SendApplicationParams(
        posting: _posting,
        resume: _resume,
        appliedAt: DateTime.fromMillisecondsSinceEpoch(0),
        extraAttachmentPaths: const <String>['/tmp/cover.pdf', '/tmp/portfolio.pdf'],
      ),
    );

    final EmailDraft draft =
        verify(() => gmail.sendEmail(captureAny())).captured.single
            as EmailDraft;
    expect(draft.attachmentPaths, <String>[
      '/tmp/resume.pdf',
      '/tmp/cover.pdf',
      '/tmp/portfolio.pdf',
    ]);
  });

  test('does NOT save when sending fails', () async {
    when(() => gmail.sendEmail(any())).thenAnswer(
      (_) async => const Left<Failure, SentEmail>(GmailFailure('send failed')),
    );

    final result = await useCase(_params());

    expect(result.isLeft(), isTrue);
    verifyNever(() => apps.save(any()));
  });
}
