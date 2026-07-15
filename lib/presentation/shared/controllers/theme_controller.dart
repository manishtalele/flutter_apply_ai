import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Reactive theme-mode holder used by [GetMaterialApp] and the Settings
/// screen's theme toggle. Registered as a permanent service in
/// [InitialBinding]. Persistence to `SettingsRepository` is wired in Module 12
/// (`loadPersistedMode`/`_persist` are the integration points).
class ThemeController extends GetxService {
  final Rx<ThemeMode> _mode = ThemeMode.dark.obs;

  ThemeMode get mode => _mode.value;

  bool get isDarkMode => _mode.value == ThemeMode.dark;

  /// Applies [mode] to the live app and updates observers.
  void setMode(ThemeMode mode) {
    if (_mode.value == mode) {
      return;
    }
    _mode.value = mode;
    Get.changeThemeMode(mode);
  }

  /// Toggles between light and dark. `ThemeMode.system` resolves to the
  /// opposite of the currently-rendered brightness.
  void toggle() {
    setMode(isDarkMode ? ThemeMode.light : ThemeMode.dark);
  }
}
