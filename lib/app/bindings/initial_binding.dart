import 'package:flutter_apply_ai/core/utils/app_logger.dart';
import 'package:flutter_apply_ai/presentation/shared/controllers/theme_controller.dart';
import 'package:get/get.dart';

/// Registers process-wide singletons that must exist before the first route
/// is built and must survive for the app's entire lifetime.
///
/// Attached to [GetMaterialApp.initialBinding]. Only truly global, cheap-to-
/// construct dependencies belong here; per-feature dependencies live in their
/// own route [Bindings]. Async singletons that require `await` (e.g.
/// SharedPreferences, the database) are added in later modules via
/// `Get.putAsync` alongside their datasources.
class InitialBinding extends Bindings {
  InitialBinding();

  @override
  void dependencies() {
    // Idempotent safety net: in production `ServiceLocator.init()` has already
    // registered these before `runApp`; in widget tests (which skip the async
    // bootstrap) this ensures the app still has a logger and theme controller.
    if (!Get.isRegistered<AppLogger>()) {
      Get.put<AppLogger>(ConsoleAppLogger(), permanent: true);
    }
    if (!Get.isRegistered<ThemeController>()) {
      Get.put<ThemeController>(ThemeController(), permanent: true);
    }
  }
}
