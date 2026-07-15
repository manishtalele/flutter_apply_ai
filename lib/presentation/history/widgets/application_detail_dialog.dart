import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_apply_ai/core/theme/app_dimensions.dart';
import 'package:flutter_apply_ai/core/utils/date_formatter.dart';
import 'package:flutter_apply_ai/domain/entities/application.dart';
import 'package:flutter_apply_ai/presentation/history/controllers/history_controller.dart';
import 'package:flutter_apply_ai/presentation/shared/widgets/app_button.dart';
import 'package:flutter_apply_ai/presentation/shared/widgets/status_chip.dart';

/// Read-only detail view of a stored application, with an action to open the
/// related conversation in Gmail.
class ApplicationDetailDialog extends StatelessWidget {
  const ApplicationDetailDialog({
    required this.application,
    required this.controller,
    super.key,
  });

  final Application application;
  final HistoryController controller;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return AlertDialog(
      title: Row(
        children: <Widget>[
          Expanded(child: Text(application.company)),
          StatusChip(status: application.status),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _row('Role', application.role),
              _row('Email', application.email),
              _row('Location', application.location),
              _row('Match score', '${application.matchScore}'),
              _row('Resume', application.resumeName),
              _row('Applied', DateFormatter.dateTime(application.appliedAt)),
              const SizedBox(height: AppDimensions.spaceMd),
              Text('Subject', style: theme.textTheme.labelMedium),
              const SizedBox(height: 4),
              SelectableText(application.subject),
              const SizedBox(height: AppDimensions.spaceMd),
              Text('Email body', style: theme.textTheme.labelMedium),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimensions.spaceMd),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: SelectableText(application.emailBody),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        AppButton(
          label: 'Open in Gmail',
          icon: Icons.open_in_new_rounded,
          variant: AppButtonVariant.outlined,
          onPressed: () => unawaited(controller.openInGmail(application)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: SelectableText(value.isEmpty ? '—' : value),
          ),
        ],
      ),
    );
  }
}
