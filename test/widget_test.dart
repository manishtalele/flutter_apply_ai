import 'package:flutter_apply_ai/core/constants/app_constants.dart';
import 'package:flutter_apply_ai/core/utils/app_logger.dart';
import 'package:flutter_apply_ai/presentation/splash/controllers/splash_controller.dart';
import 'package:flutter_apply_ai/presentation/splash/views/splash_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _SilentLogger implements AppLogger {
  const _SilentLogger();

  @override
  void d(String message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void i(String message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void w(String message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void e(String message, [Object? error, StackTrace? stackTrace]) {}
}

/// Splash controller whose bootstrap (timer + navigation to the Shell) is
/// skipped, so the smoke test can verify the splash UI deterministically
/// without a pending timer or requiring the full DI graph.
class _StaticSplashController extends SplashController {
  _StaticSplashController() : super(const _SilentLogger());

  @override
  void onReady() {}
}

void main() {
  testWidgets('Splash screen renders the app identity', (WidgetTester tester) async {
    Get.put<SplashController>(_StaticSplashController());
    addTearDown(Get.reset);

    await tester.pumpWidget(const GetMaterialApp(home: SplashView()));

    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.text(AppConstants.appTagline), findsOneWidget);
  });
}
