import 'package:flutter/material.dart';
import 'package:flutter_apply_ai/core/enums/view_state.dart';
import 'package:flutter_apply_ai/core/theme/app_colors.dart';
import 'package:flutter_apply_ai/core/theme/app_dimensions.dart';
import 'package:flutter_apply_ai/domain/entities/application.dart';
import 'package:flutter_apply_ai/presentation/history/controllers/history_controller.dart';
import 'package:flutter_apply_ai/presentation/history/widgets/application_tile.dart';
import 'package:flutter_apply_ai/presentation/history/widgets/history_filter_bar.dart';
import 'package:flutter_apply_ai/presentation/shared/widgets/app_empty_state.dart';
import 'package:get/get.dart';

/// History screen: searchable, filterable list of past applications.
class HistoryView extends GetView<HistoryController> {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('History', style: theme.textTheme.headlineMedium),
          const SizedBox(height: AppDimensions.spaceMd),
          HistoryFilterBar(controller: controller),
          const SizedBox(height: AppDimensions.spaceMd),
          Expanded(
            child: Obx(() {
              switch (controller.state.value) {
                case ViewState.initial:
                case ViewState.loading:
                  return const Center(child: CircularProgressIndicator());
                case ViewState.error:
                  return AppEmptyState(
                    icon: Icons.error_outline_rounded,
                    iconColor: AppColors.error,
                    title: 'Could not load history',
                    actionLabel: 'Retry',
                    onAction: controller.reload,
                  );
                case ViewState.success:
                  final List<Application> apps = controller.applications;
                  if (apps.isEmpty) {
                    return const AppEmptyState(
                      icon: Icons.inbox_outlined,
                      title: 'No applications yet',
                      message: 'Applications you send will appear here.',
                    );
                  }
                  return ListView.builder(
                    itemCount: apps.length,
                    itemBuilder: (BuildContext context, int index) =>
                        ApplicationTile(
                      application: apps[index],
                      controller: controller,
                    ),
                  );
              }
            }),
          ),
        ],
      ),
    );
  }
}
