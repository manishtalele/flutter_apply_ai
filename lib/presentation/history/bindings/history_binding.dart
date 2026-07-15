import 'package:flutter_apply_ai/core/utils/app_logger.dart';
import 'package:flutter_apply_ai/domain/usecases/application/delete_application_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/application/export_applications_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/application/get_applications_usecase.dart';
import 'package:flutter_apply_ai/presentation/history/controllers/history_controller.dart';
import 'package:get/get.dart';

/// Provides [HistoryController] and its use cases.
class HistoryBinding extends Bindings {
  HistoryBinding();

  @override
  void dependencies() {
    Get.lazyPut<HistoryController>(
      () => HistoryController(
        getApplications: Get.find<GetApplicationsUseCase>(),
        deleteApplication: Get.find<DeleteApplicationUseCase>(),
        exportApplications: Get.find<ExportApplicationsUseCase>(),
        logger: Get.find<AppLogger>(),
      ),
    );
  }
}
