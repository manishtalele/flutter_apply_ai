import 'package:equatable/equatable.dart';

/// Identifiers returned by the Gmail API after a message is sent. Persisted on
/// the [Application] so reply-tracking can later query the same thread.
class SentEmail extends Equatable {
  const SentEmail({
    required this.messageId,
    required this.threadId,
  });

  final String messageId;
  final String threadId;

  @override
  List<Object?> get props => <Object?>[messageId, threadId];
}
