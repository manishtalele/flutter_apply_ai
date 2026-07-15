import 'package:flutter_apply_ai/core/utils/app_logger.dart';
import 'package:flutter_apply_ai/domain/usecases/ai/analyze_job_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/application/check_duplicate_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/application/send_application_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/resume/get_resumes_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/settings/get_settings_usecase.dart';
import 'package:flutter_apply_ai/presentation/home/controllers/home_controller.dart';
import 'package:get/get.dart';

/// Provides [HomeController] and its dependencies. Registered by the Shell
/// binding so the embedded Home tab has its controller available.
class HomeBinding extends Bindings {
  HomeBinding();

  @override
  void dependencies() {
    Get.lazyPut<HomeController>(
      () => HomeController(
        analyzeJob: Get.find<AnalyzeJobUseCase>(),
        checkDuplicate: Get.find<CheckDuplicateUseCase>(),
        sendApplication: Get.find<SendApplicationUseCase>(),
        getResumes: Get.find<GetResumesUseCase>(),
        getSettings: Get.find<GetSettingsUseCase>(),
        logger: Get.find<AppLogger>(),
      ),
    );
  }
}
