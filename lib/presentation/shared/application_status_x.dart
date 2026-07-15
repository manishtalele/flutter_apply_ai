import 'package:flutter/material.dart';
import 'package:flutter_apply_ai/core/theme/app_colors.dart';
import 'package:flutter_apply_ai/domain/entities/enums/application_status.dart';

/// Presentation mapping of [ApplicationStatus] to its display color and icon.
/// Lives in Presentation (Flutter types); shared by History and Dashboard.
extension ApplicationStatusX on ApplicationStatus {
  Color get color {
    return switch (this) {
      ApplicationStatus.applied => AppColors.statusApplied,
      ApplicationStatus.interview => AppColors.statusInterview,
      ApplicationStatus.selected => AppColors.statusSelected,
      ApplicationStatus.rejected => AppColors.statusRejected,
      ApplicationStatus.noReply => AppColors.statusNoReply,
    };
  }

  IconData get icon {
    return switch (this) {
      ApplicationStatus.applied => Icons.send_rounded,
      ApplicationStatus.interview => Icons.event_available_rounded,
      ApplicationStatus.selected => Icons.emoji_events_rounded,
      ApplicationStatus.rejected => Icons.cancel_rounded,
      ApplicationStatus.noReply => Icons.hourglass_empty_rounded,
    };
  }
}
