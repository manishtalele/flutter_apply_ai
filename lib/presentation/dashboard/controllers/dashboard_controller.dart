import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_apply_ai/core/enums/view_state.dart';
import 'package:flutter_apply_ai/core/errors/failures.dart';
import 'package:flutter_apply_ai/core/utils/app_logger.dart';
import 'package:flutter_apply_ai/domain/entities/dashboard_stats.dart';
import 'package:flutter_apply_ai/domain/usecases/dashboard/get_dashboard_stats_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/gmail/sync_replies_usecase.dart';
import 'package:flutter_apply_ai/presentation/shell/controllers/shell_controller.dart';
import 'package:get/get.dart';

/// ViewModel for the Dashboard: aggregate stats + a reply-sync action.
class DashboardController extends GetxController {
  DashboardController({
    required GetDashboardStatsUseCase getStats,
    required SyncRepliesUseCase syncReplies,
    required AppLogger logger,
  })  : _getStats = getStats,
        _syncReplies = syncReplies,
        _logger = logger;

  final GetDashboardStatsUseCase _getStats;
  final SyncRepliesUseCase _syncReplies;
  final AppLogger _logger;

  static const int _dashboardTabIndex = 1;

  final Rx<ViewState> state = ViewState.initial.obs;
  final Rx<DashboardStats> stats = DashboardStats.empty.obs;
  final RxBool syncing = false.obs;

  Worker? _tabWorker;

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
    if (Get.isRegistered<ShellController>()) {
      _tabWorker = ever<int>(
        Get.find<ShellController>().currentIndex,
        (int index) {
          if (index == _dashboardTabIndex) {
            unawaited(load());
          }
        },
      );
    }
  }

  Future<void> load() async {
    if (state.value != ViewState.success) {
      state.value = ViewState.loading;
    }
    final result = await _getStats(DateTime.now());
    result.fold(
      (Failure failure) {
        _logger.w('Failed to load dashboard stats: ${failure.message}');
        state.value = ViewState.error;
      },
      (DashboardStats value) {
        stats.value = value;
        state.value = ViewState.success;
      },
    );
  }

  Future<void> syncReplies() async {
    if (syncing.value) {
      return;
    }
    syncing.value = true;
    final result = await _syncReplies(DateTime.now());
    syncing.value = false;

    result.fold(
      (Failure failure) => _notify('Sync failed', failure.message),
      (int updated) {
        _notify(
          'Replies synced',
          updated == 0
              ? 'No status changes found.'
              : '$updated application(s) updated.',
        );
        unawaited(load());
      },
    );
  }

  void _notify(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void onClose() {
    _tabWorker?.dispose();
    super.onClose();
  }
}
