import 'package:flutter_apply_ai/core/utils/app_logger.dart';
import 'package:flutter_apply_ai/presentation/splash/controllers/splash_controller.dart';
import 'package:get/get.dart';

/// Route binding for the splash screen. Injects the globally-registered
/// [AppLogger] into [SplashController].
class SplashBinding extends Bindings {
  SplashBinding();

  @override
  void dependencies() {
    // The splash view only displays static UI and never reads `controller`.
    // A lazy registration would therefore never instantiate the controller,
    // so its `onReady` bootstrap (and the route transition) would not run.
    Get.put<SplashController>(SplashController(Get.find<AppLogger>()));
  }
}
