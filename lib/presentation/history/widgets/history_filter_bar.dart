import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_apply_ai/core/theme/app_dimensions.dart';
import 'package:flutter_apply_ai/domain/entities/enums/application_status.dart';
import 'package:flutter_apply_ai/presentation/history/controllers/history_controller.dart';
import 'package:flutter_apply_ai/presentation/shared/widgets/app_button.dart';
import 'package:get/get.dart';

/// Search box + status filter + export/refresh actions for the History screen.
class HistoryFilterBar extends StatelessWidget {
  const HistoryFilterBar({required this.controller, super.key});

  final HistoryController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: TextField(
            controller: controller.searchController,
            onChanged: controller.onSearchChanged,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Search company, role, email, or location…',
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.spaceSm),
        Obx(
          () => DropdownMenu<ApplicationStatus?>(
            initialSelection: controller.statusFilter.value,
            label: const Text('Status'),
            onSelected: (ApplicationStatus? status) =>
                unawaited(controller.setStatusFilter(status)),
            dropdownMenuEntries: <DropdownMenuEntry<ApplicationStatus?>>[
              const DropdownMenuEntry<ApplicationStatus?>(
                value: null,
                label: 'All',
              ),
              ...ApplicationStatus.values.map(
                (ApplicationStatus s) => DropdownMenuEntry<ApplicationStatus?>(
                  value: s,
                  label: s.label,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppDimensions.spaceSm),
        Obx(
          () => AppButton(
            label: 'Export CSV',
            icon: Icons.download_rounded,
            variant: AppButtonVariant.outlined,
            isLoading: controller.exporting.value,
            onPressed: controller.exportCsv,
          ),
        ),
        const SizedBox(width: AppDimensions.spaceXs),
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () => unawaited(controller.reload()),
        ),
      ],
    );
  }
}
