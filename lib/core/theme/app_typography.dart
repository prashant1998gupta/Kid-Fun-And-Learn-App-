import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography for KidVerse.
///
/// - **Baloo 2** for display/headlines: rounded, chunky, joyful — reads as
///   "friendly" to children and is highly legible at large sizes.
/// - **Nunito** for body/UI: humanist, rounded terminals, excellent small-size
///   legibility (used by many kids' products for exactly this reason).
///
/// Sizes are deliberately large. Minimal reading is a product goal, so when we
/// DO use text it must be effortless.
class AppTypography {
  AppTypography._();

  static TextTheme textTheme(Color color, Color softColor) {
    final display = GoogleFonts.baloo2TextTheme();
    final body = GoogleFonts.nunitoTextTheme();

    return TextTheme(
      displayLarge: display.displayLarge?.copyWith(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.05,
      ),
      displayMedium: display.displayMedium?.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        color: color,
      ),
      headlineLarge: display.headlineLarge?.copyWith(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: color,
      ),
      headlineMedium: display.headlineMedium?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: color,
      ),
      titleLarge: display.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: color,
      ),
      bodyLarge: body.bodyLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.4,
      ),
      bodyMedium: body.bodyMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: softColor,
        height: 1.4,
      ),
      labelLarge: body.labelLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: color,
        letterSpacing: 0.3,
      ),
      labelMedium: body.labelMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: softColor,
      ),
    );
  }

  static TextTheme get light =>
      textTheme(AppColors.lightText, AppColors.lightTextSoft);
  static TextTheme get dark =>
      textTheme(AppColors.darkText, AppColors.darkTextSoft);
}
