import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Assembles Material 3 [ThemeData] for light & dark, tuned for kids.
class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      tertiary: AppColors.mint,
      onTertiary: AppColors.lightText,
      error: AppColors.error,
      onError: Colors.white,
      surface: isLight ? AppColors.lightSurface : AppColors.darkSurface,
      onSurface: isLight ? AppColors.lightText : AppColors.darkText,
      surfaceContainerHighest:
          isLight ? AppColors.lightSurfaceAlt : AppColors.darkSurfaceAlt,
    );

    final textTheme = isLight ? AppTypography.light : AppTypography.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isLight ? AppColors.lightBg : AppColors.darkBg,
      textTheme: textTheme,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.headlineMedium,
        foregroundColor: scheme.onSurface,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 6,
        shadowColor: AppColors.primary.withValues(alpha: 0.18),
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.cardRadius,
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize:
              const Size(AppSpacing.minTouchTarget, AppSpacing.minTouchTarget),
          textStyle: textTheme.labelLarge,
          shape: const RoundedRectangleBorder(
            borderRadius: AppSpacing.buttonRadius,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.sheetRadius),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(AppSpacing.radiusMd),
        ),
        backgroundColor: AppColors.primaryDark,
        contentTextStyle: textTheme.bodyLarge?.copyWith(color: Colors.white),
      ),
    );
  }
}
