import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_apply_ai/app/app.dart';
import 'package:flutter_apply_ai/core/constants/app_constants.dart';
import 'package:flutter_apply_ai/core/di/service_locator.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';

/// Application entry point.
///
/// Performs the platform bootstrap that must complete before the widget tree
/// is built: binding initialization, SQLite FFI wiring for desktop, and
/// desktop window configuration. Feature dependencies are provided by GetX
/// bindings (see `InitialBinding` and per-route bindings), not here.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _initializeDatabaseFactory();
  await ServiceLocator.init();
  await _initializeDesktopWindow();

  runApp(const ApplyAiApp());
}

/// `sqflite` ships no native implementation for desktop platforms, so the
/// default [databaseFactory] is routed through the FFI backend
/// (`sqflite_common_ffi`) backed by the bundled `sqlite3` library.
void _initializeDatabaseFactory() {
  if (!kIsWeb &&
      (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}

/// Configures the native desktop window (size, minimum size, centering,
/// title) using `window_manager`. No-op on non-desktop platforms.
Future<void> _initializeDesktopWindow() async {
  if (kIsWeb ||
      !(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    return;
  }

  await windowManager.ensureInitialized();

  const WindowOptions options = WindowOptions(
    size: Size(
      AppConstants.initialWindowWidth,
      AppConstants.initialWindowHeight,
    ),
    minimumSize: Size(
      AppConstants.minWindowWidth,
      AppConstants.minWindowHeight,
    ),
    center: true,
    title: AppConstants.appName,
    titleBarStyle: TitleBarStyle.normal,
  );

  await windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.show();
    await windowManager.focus();
  });
}
