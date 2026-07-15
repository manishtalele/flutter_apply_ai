import 'package:flutter/material.dart';
import 'package:flutter_apply_ai/domain/entities/enums/app_theme_mode.dart';

/// Maps the pure-Dart domain [AppThemeMode] to Flutter's [ThemeMode] and back.
/// Kept in Presentation because [ThemeMode] is a Flutter type (Domain stays
/// framework-agnostic).
extension AppThemeModeX on AppThemeMode {
  ThemeMode get toThemeMode {
    return switch (this) {
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
      AppThemeMode.system => ThemeMode.system,
    };
  }
}

extension ThemeModeX on ThemeMode {
  AppThemeMode get toAppThemeMode {
    return switch (this) {
      ThemeMode.light => AppThemeMode.light,
      ThemeMode.dark => AppThemeMode.dark,
      ThemeMode.system => AppThemeMode.system,
    };
  }
}
