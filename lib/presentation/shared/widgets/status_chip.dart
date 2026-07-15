import 'package:flutter/material.dart';
import 'package:flutter_apply_ai/core/theme/app_dimensions.dart';
import 'package:flutter_apply_ai/domain/entities/enums/application_status.dart';
import 'package:flutter_apply_ai/presentation/shared/application_status_x.dart';

/// Compact colored chip showing an application's [ApplicationStatus].
class StatusChip extends StatelessWidget {
  const StatusChip({required this.status, super.key});

  final ApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    final Color color = status.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(status.icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
