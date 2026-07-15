import 'package:flutter_apply_ai/app/routes/app_routes.dart';
import 'package:flutter_apply_ai/presentation/shell/bindings/shell_binding.dart';
import 'package:flutter_apply_ai/presentation/shell/views/shell_view.dart';
import 'package:flutter_apply_ai/presentation/splash/bindings/splash_binding.dart';
import 'package:flutter_apply_ai/presentation/splash/views/splash_view.dart';
import 'package:get/get.dart';

/// Route table consumed by [GetMaterialApp].
///
/// Each [GetPage] binds its View to its dependency [Bindings], so controllers
/// are created lazily on navigation and disposed on route exit. Additional
/// pages (Shell, Home, Settings, History, Dashboard) are appended here in
/// their respective modules.
abstract final class AppPages {
  const AppPages._();

  static const String initial = AppRoutes.splash;

  static final List<GetPage<dynamic>> pages = <GetPage<dynamic>>[
    GetPage<dynamic>(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.shell,
      page: () => const ShellView(),
      binding: ShellBinding(),
    ),
    // Home/Settings/History/Dashboard live inside the Shell (IndexedStack),
    // not as separate top-level routes.
  ];
}
