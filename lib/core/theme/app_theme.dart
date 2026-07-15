import 'package:flutter/material.dart';

import 'package:flutter_apply_ai/core/theme/app_colors.dart';
import 'package:flutter_apply_ai/core/theme/app_dimensions.dart';
import 'package:flutter_apply_ai/core/theme/app_text_styles.dart';

/// Composes the application's light and dark Material 3 themes from the design
/// tokens (`AppColors`, `AppDimensions`, `AppTextStyles`). All component
/// theming (cards, buttons, inputs, chips, nav rail, dialogs) is centralized
/// here so individual widgets stay declarative and visually consistent.
abstract final class AppTheme {
  const AppTheme._();

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        background: AppColors.darkBackground,
        surface: AppColors.darkSurface,
        surfaceVariant: AppColors.darkSurfaceVariant,
        outline: AppColors.darkOutline,
        onSurface: AppColors.darkOnSurface,
        onSurfaceMuted: AppColors.darkOnSurfaceMuted,
      );

  static ThemeData get light => _build(
        brightness: Brightness.light,
        background: AppColors.lightBackground,
        surface: AppColors.lightSurface,
        surfaceVariant: AppColors.lightSurfaceVariant,
        outline: AppColors.lightOutline,
        onSurface: AppColors.lightOnSurface,
        onSurfaceMuted: AppColors.lightOnSurfaceMuted,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color surfaceVariant,
    required Color outline,
    required Color onSurface,
    required Color onSurfaceMuted,
  }) {
    final ColorScheme colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: AppColors.white,
      primaryContainer: AppColors.primaryVariant,
      onPrimaryContainer: AppColors.white,
      secondary: AppColors.secondary,
      onSecondary: AppColors.white,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.white,
      error: AppColors.error,
      onError: AppColors.white,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceMuted,
      surfaceContainerHighest: surfaceVariant,
      outline: outline,
      outlineVariant: outline,
    );

    final TextTheme textTheme = AppTextStyles.buildTextTheme(
      onSurface: onSurface,
      onSurfaceMuted: onSurfaceMuted,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      cardTheme: CardThemeData(
        color: surface,
        elevation: AppDimensions.elevationCard,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          side: BorderSide(color: outline, width: AppDimensions.borderThin),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: AppColors.transparent,
        elevation: AppDimensions.elevationNone,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: onSurface),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _filledButtonStyle(colorScheme, textTheme),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _filledButtonStyle(colorScheme, textTheme),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          minimumSize: const Size(0, AppDimensions.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceLg,
          ),
          textStyle: textTheme.labelLarge,
          side: BorderSide(color: outline, width: AppDimensions.borderThin),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: onSurface),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceMd,
          vertical: AppDimensions.spaceMd,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: onSurfaceMuted),
        labelStyle: textTheme.bodyMedium?.copyWith(color: onSurfaceMuted),
        border: _inputBorder(outline),
        enabledBorder: _inputBorder(outline),
        focusedBorder: _inputBorder(colorScheme.primary, width: 1.5),
        errorBorder: _inputBorder(colorScheme.error),
        focusedErrorBorder: _inputBorder(colorScheme.error, width: 1.5),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant,
        side: BorderSide(color: outline, width: AppDimensions.borderThin),
        labelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceSm,
          vertical: AppDimensions.spaceXxs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: outline,
        thickness: AppDimensions.borderThin,
        space: AppDimensions.spaceMd,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.16),
        selectedIconTheme: IconThemeData(color: colorScheme.primary),
        unselectedIconTheme: IconThemeData(color: onSurfaceMuted),
        selectedLabelTextStyle: textTheme.labelLarge?.copyWith(
          color: colorScheme.primary,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium,
        useIndicator: true,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: AppDimensions.elevationDialog,
        surfaceTintColor: AppColors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceVariant,
        contentTextStyle: textTheme.bodyMedium,
        behavior: SnackBarBehavior.floating,
        elevation: AppDimensions.elevationDialog,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: onSurface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        ),
        textStyle: textTheme.labelSmall?.copyWith(color: surface),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: surfaceVariant,
        circularTrackColor: surfaceVariant,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll<Color>(
          onSurfaceMuted.withValues(alpha: 0.4),
        ),
        radius: const Radius.circular(AppDimensions.radiusPill),
        thickness: const WidgetStatePropertyAll<double>(6),
      ),
    );
  }

  static ButtonStyle _filledButtonStyle(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return FilledButton.styleFrom(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      disabledBackgroundColor: colorScheme.primary.withValues(alpha: 0.4),
      disabledForegroundColor: colorScheme.onPrimary.withValues(alpha: 0.7),
      minimumSize: const Size(0, AppDimensions.buttonHeight),
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceLg),
      textStyle: textTheme.labelLarge,
      elevation: AppDimensions.elevationNone,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
