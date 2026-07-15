import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_apply_ai/core/theme/app_dimensions.dart';
import 'package:flutter_apply_ai/core/utils/date_formatter.dart';
import 'package:flutter_apply_ai/domain/entities/application.dart';
import 'package:flutter_apply_ai/presentation/history/controllers/history_controller.dart';
import 'package:flutter_apply_ai/presentation/history/widgets/application_detail_dialog.dart';
import 'package:flutter_apply_ai/presentation/shared/widgets/app_card.dart';
import 'package:flutter_apply_ai/presentation/shared/widgets/status_chip.dart';

/// A single application row in the History list.
class ApplicationTile extends StatelessWidget {
  const ApplicationTile({
    required this.application,
    required this.controller,
    super.key,
  });

  final Application application;
  final HistoryController controller;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spaceSm),
      child: AppCard(
        padding: const EdgeInsets.all(AppDimensions.spaceMd),
        onTap: () => _openDetail(context),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                _initial,
                style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
              ),
            ),
            const SizedBox(width: AppDimensions.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    application.company.isEmpty ? '—' : application.company,
                    style: theme.textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    application.role,
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${application.email} • ${DateFormatter.relative(application.appliedAt)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.spaceSm),
            _MatchBadge(score: application.matchScore),
            const SizedBox(width: AppDimensions.spaceSm),
            StatusChip(status: application.status),
            const SizedBox(width: AppDimensions.spaceXs),
            IconButton(
              tooltip: 'Open in Gmail',
              icon: const Icon(Icons.open_in_new_rounded, size: 20),
              onPressed: () => unawaited(controller.openInGmail(application)),
            ),
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              onPressed: () => unawaited(_confirmDelete(context)),
            ),
          ],
        ),
      ),
    );
  }

  String get _initial => application.company.isEmpty
      ? '?'
      : application.company.trim().characters.first.toUpperCase();

  void _openDetail(BuildContext context) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (_) => ApplicationDetailDialog(
          application: application,
          controller: controller,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Delete application?'),
        content: Text(
          'Remove the application to ${application.company} '
          '(${application.role})? This cannot be undone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    final int? id = application.id;
    if (confirmed == true && id != null) {
      await controller.deleteApplication(id);
    }
  }
}

class _MatchBadge extends StatelessWidget {
  const _MatchBadge({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          '$score',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
        Text('match', style: theme.textTheme.labelSmall),
      ],
    );
  }
}
