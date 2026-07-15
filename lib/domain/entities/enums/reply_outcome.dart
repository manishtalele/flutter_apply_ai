import 'package:flutter_apply_ai/domain/entities/enums/application_status.dart';

/// Classification of an employer's email reply, produced by the reply-tracking
/// AI pass. Maps onto an [ApplicationStatus] used to update the stored record.
enum ReplyOutcome {
  interview('interview'),
  selected('selected'),
  rejected('rejected'),
  none('none');

  const ReplyOutcome(this.value);

  final String value;

  static ReplyOutcome fromValue(String value) {
    return ReplyOutcome.values.firstWhere(
      (ReplyOutcome outcome) => outcome.value == value,
      orElse: () => ReplyOutcome.none,
    );
  }

  /// The application status this outcome implies, or `null` when no
  /// meaningful reply was detected (leave the current status unchanged).
  ApplicationStatus? toStatus() {
    switch (this) {
      case ReplyOutcome.interview:
        return ApplicationStatus.interview;
      case ReplyOutcome.selected:
        return ApplicationStatus.selected;
      case ReplyOutcome.rejected:
        return ApplicationStatus.rejected;
      case ReplyOutcome.none:
        return null;
    }
  }
}
