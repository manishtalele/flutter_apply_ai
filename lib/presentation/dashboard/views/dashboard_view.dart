import 'package:flutter/material.dart';
import 'package:flutter_apply_ai/core/enums/view_state.dart';
import 'package:flutter_apply_ai/core/theme/app_colors.dart';
import 'package:flutter_apply_ai/core/theme/app_dimensions.dart';
import 'package:flutter_apply_ai/domain/entities/dashboard_stats.dart';
import 'package:flutter_apply_ai/presentation/dashboard/controllers/dashboard_controller.dart';
import 'package:flutter_apply_ai/presentation/dashboard/widgets/stat_card.dart';
import 'package:flutter_apply_ai/presentation/shared/widgets/app_button.dart';
import 'package:flutter_apply_ai/presentation/shared/widgets/app_empty_state.dart';
import 'package:get/get.dart';

/// Dashboard: application metrics + a reply-sync action.
class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text('Dashboard', style: theme.textTheme.headlineMedium),
              const Spacer(),
              Obx(
                () => AppButton(
                  label: 'Sync replies',
                  icon: Icons.sync_rounded,
                  variant: AppButtonVariant.outlined,
                  isLoading: controller.syncing.value,
                  onPressed: controller.syncReplies,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceLg),
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
                    title: 'Could not load stats',
                    actionLabel: 'Retry',
                    onAction: controller.load,
                  );
                case ViewState.success:
                  return _StatsGrid(stats: controller.stats.value);
              }
            }),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final List<_Metric> metrics = <_Metric>[
      _Metric('Applied Today', stats.appliedToday, Icons.today_rounded,
          AppColors.primary),
      _Metric('This Week', stats.appliedThisWeek, Icons.date_range_rounded,
          AppColors.primary),
      _Metric('This Month', stats.appliedThisMonth,
          Icons.calendar_month_rounded, AppColors.primary),
      _Metric('Total Applied', stats.totalApplied, Icons.mail_rounded,
          AppColors.secondary),
      _Metric('Replies', stats.replies, Icons.mark_email_read_rounded,
          AppColors.info),
      _Metric('Interviews', stats.interviews, Icons.event_available_rounded,
          AppColors.statusInterview),
      _Metric('Selected', stats.selected, Icons.emoji_events_rounded,
          AppColors.statusSelected),
      _Metric('Rejected', stats.rejected, Icons.cancel_rounded,
          AppColors.statusRejected),
      _Metric('No Reply', stats.noReply, Icons.hourglass_empty_rounded,
          AppColors.statusNoReply),
    ];

    return SingleChildScrollView(
      child: Wrap(
        spacing: AppDimensions.spaceMd,
        runSpacing: AppDimensions.spaceMd,
        children: metrics
            .map(
              (_Metric m) => SizedBox(
                width: 220,
                child: StatCard(
                  label: m.label,
                  value: '${m.value}',
                  icon: m.icon,
                  accent: m.accent,
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _Metric {
  const _Metric(this.label, this.value, this.icon, this.accent);

  final String label;
  final int value;
  final IconData icon;
  final Color accent;
}
