import 'package:flutter/material.dart';
import 'package:flutter_apply_ai/app/bindings/initial_binding.dart';
import 'package:flutter_apply_ai/app/routes/app_pages.dart';
import 'package:flutter_apply_ai/core/constants/app_constants.dart';
import 'package:flutter_apply_ai/core/theme/app_theme.dart';
import 'package:get/get.dart';

/// Root application widget.
///
/// Uses [GetMaterialApp] to unify routing, dependency injection, and theming.
/// The live theme mode is driven imperatively by `ThemeController`
/// (`Get.changeThemeMode`); the initial mode is dark per the design spec.
class ApplyAiApp extends StatelessWidget {
  const ApplyAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      initialBinding: InitialBinding(),
      initialRoute: AppPages.initial,
      getPages: AppPages.pages,
      defaultTransition: Transition.cupertino,
      transitionDuration: AppConstants.routeTransitionDuration,
    );
  }
}
