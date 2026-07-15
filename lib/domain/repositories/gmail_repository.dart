import 'package:flutter_apply_ai/core/utils/typedefs.dart';
import 'package:flutter_apply_ai/domain/entities/email_draft.dart';
import 'package:flutter_apply_ai/domain/entities/sent_email.dart';

/// Gmail contract (OAuth2 + send + reply lookup). The interface lives in
/// Domain; the implementation (Modules 10/16/17) hides OAuth and the Gmail
/// REST API.
abstract interface class GmailRepository {
  /// Runs the OAuth2 consent flow and returns the connected account's email.
  ResultFuture<String> connect();

  ResultFuture<void> disconnect();

  /// Whether a valid session currently exists.
  ResultFuture<bool> isConnected();

  /// The connected account email, or `null` if not connected.
  ResultFuture<String?> connectedAccount();

  /// Sends [draft] (HTML body + attachments) and returns the Gmail message and
  /// thread identifiers.
  ResultFuture<SentEmail> sendEmail(EmailDraft draft);

  /// Returns the body of the most recent incoming message on [threadId] (i.e.
  /// not sent by the user), or `null` if there has been no reply.
  ResultFuture<String?> fetchLatestIncomingReply(String threadId);
}
