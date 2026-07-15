import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_apply_ai/core/errors/failures.dart';
import 'package:flutter_apply_ai/core/utils/typedefs.dart';
import 'package:flutter_apply_ai/domain/entities/application.dart';
import 'package:flutter_apply_ai/domain/entities/email_draft.dart';
import 'package:flutter_apply_ai/domain/entities/enums/application_status.dart';
import 'package:flutter_apply_ai/domain/entities/job_posting.dart';
import 'package:flutter_apply_ai/domain/entities/resume_profile.dart';
import 'package:flutter_apply_ai/domain/entities/sent_email.dart';
import 'package:flutter_apply_ai/domain/repositories/application_repository.dart';
import 'package:flutter_apply_ai/domain/repositories/gmail_repository.dart';
import 'package:flutter_apply_ai/domain/usecases/usecase.dart';

/// Parameters for [SendApplicationUseCase].
class SendApplicationParams extends Equatable {
  const SendApplicationParams({
    required this.posting,
    required this.resume,
    required this.appliedAt,
    this.senderName = '',
    this.extraAttachmentPaths = const <String>[],
  });

  final JobPosting posting;
  final ResumeProfile resume;
  final String senderName;

  /// Additional files to attach alongside the resume.
  final List<String> extraAttachmentPaths;

  /// The apply timestamp — passed in (not read from the clock) so the
  /// use case stays deterministic and testable.
  final DateTime appliedAt;

  @override
  List<Object?> get props => <Object?>[
        posting,
        resume,
        senderName,
        extraAttachmentPaths,
        appliedAt,
      ];
}

/// Orchestrates sending an application: build the email + attach the resume,
/// send it via Gmail, then persist the record. If sending fails the record is
/// NOT saved (no orphan "applied" rows for emails that never went out).
class SendApplicationUseCase
    implements UseCase<Application, SendApplicationParams> {
  const SendApplicationUseCase({
    required GmailRepository gmailRepository,
    required ApplicationRepository applicationRepository,
  })  : _gmail = gmailRepository,
        _applications = applicationRepository;

  final GmailRepository _gmail;
  final ApplicationRepository _applications;

  @override
  ResultFuture<Application> call(SendApplicationParams params) async {
    final JobPosting posting = params.posting;
    final EmailDraft draft = EmailDraft(
      recipient: posting.email,
      subject: posting.subject,
      htmlBody: posting.emailBody,
      attachmentPaths: <String>[
        params.resume.filePath,
        ...params.extraAttachmentPaths,
      ],
      senderName: params.senderName,
    );

    final Either<Failure, SentEmail> sendResult =
        await _gmail.sendEmail(draft);

    return sendResult.fold(
      (Failure failure) async => Left<Failure, Application>(failure),
      (SentEmail sent) async {
        final Application application = _buildApplication(params, sent);
        return _applications.save(application);
      },
    );
  }

  Application _buildApplication(
    SendApplicationParams params,
    SentEmail sent,
  ) {
    final JobPosting posting = params.posting;
    return Application(
      company: posting.company,
      email: posting.email,
      role: posting.role,
      location: posting.location,
      subject: posting.subject,
      emailBody: posting.emailBody,
      matchScore: posting.matchScore,
      status: ApplicationStatus.applied,
      resumeName: params.resume.label,
      gmailMessageId: sent.messageId,
      gmailThreadId: sent.threadId,
      appliedAt: params.appliedAt,
      updatedAt: params.appliedAt,
    );
  }
}
