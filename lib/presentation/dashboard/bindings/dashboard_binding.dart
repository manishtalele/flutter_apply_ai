import 'package:flutter_apply_ai/core/utils/app_logger.dart';
import 'package:flutter_apply_ai/domain/usecases/dashboard/get_dashboard_stats_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/gmail/sync_replies_usecase.dart';
import 'package:flutter_apply_ai/presentation/dashboard/controllers/dashboard_controller.dart';
import 'package:get/get.dart';

/// Provides [DashboardController] and its use cases.
class DashboardBinding extends Bindings {
  DashboardBinding();

  @override
  void dependencies() {
    Get.lazyPut<DashboardController>(
      () => DashboardController(
        getStats: Get.find<GetDashboardStatsUseCase>(),
        syncReplies: Get.find<SyncRepliesUseCase>(),
        logger: Get.find<AppLogger>(),
      ),
    );
  }
}
