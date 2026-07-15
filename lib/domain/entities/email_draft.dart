import 'package:equatable/equatable.dart';

/// An email ready to be sent through the Gmail API: recipient, subject, an
/// HTML body, and zero or more attachment file paths (resumes). Built from a
/// [JobPosting] plus the selected resume at apply-time.
class EmailDraft extends Equatable {
  const EmailDraft({
    required this.recipient,
    required this.subject,
    required this.htmlBody,
    this.attachmentPaths = const <String>[],
    this.senderName = '',
  });

  final String recipient;
  final String subject;
  final String htmlBody;
  final List<String> attachmentPaths;
  final String senderName;

  bool get hasAttachments => attachmentPaths.isNotEmpty;

  EmailDraft copyWith({
    String? recipient,
    String? subject,
    String? htmlBody,
    List<String>? attachmentPaths,
    String? senderName,
  }) {
    return EmailDraft(
      recipient: recipient ?? this.recipient,
      subject: subject ?? this.subject,
      htmlBody: htmlBody ?? this.htmlBody,
      attachmentPaths: attachmentPaths ?? this.attachmentPaths,
      senderName: senderName ?? this.senderName,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        recipient,
        subject,
        htmlBody,
        attachmentPaths,
        senderName,
      ];
}
