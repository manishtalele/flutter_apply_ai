import 'dart:async';

import 'package:flutter_apply_ai/app/routes/app_routes.dart';
import 'package:flutter_apply_ai/core/constants/app_constants.dart';
import 'package:flutter_apply_ai/core/utils/app_logger.dart';
import 'package:get/get.dart';

/// ViewModel for the splash / bootstrap screen.
///
/// Owns the startup sequence: it logs lifecycle events and enforces a minimum
/// branding display window. As later modules add global async dependencies
/// (settings load, session restore), their readiness checks are awaited here
/// before the app routes onward to the Shell (navigation wired in Module 11).
class SplashController extends GetxController {
  SplashController(this._logger);

  final AppLogger _logger;

  @override
  void onReady() {
    super.onReady();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    _logger.i('Application bootstrap started.');
    await Future<void>.delayed(AppConstants.splashMinDuration);
    _logger.i('Application bootstrap completed.');
    await Get.offAllNamed<void>(AppRoutes.shell);
  }
}
