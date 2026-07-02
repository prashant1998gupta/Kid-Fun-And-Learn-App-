import 'package:flutter/material.dart';

/// KidVerse color system.
///
/// Grounded in child-psychology research:
/// - Warm, saturated-but-not-harsh primaries read as "friendly & safe".
/// - Pastel surfaces reduce visual fatigue for long sessions.
/// - Each subject owns a signature hue so kids navigate by color, not reading.
/// - All foreground/background pairs below meet WCAG AA (4.5:1) for body text
///   or AA-large (3:1) for the big kid-facing titles.
class AppColors {
  AppColors._();

  // ---- Brand primaries -------------------------------------------------
  static const Color primary = Color(0xFF6C5CE7); // playful violet
  static const Color primaryDark = Color(0xFF4B3FB8);
  static const Color secondary = Color(0xFFFF7675); // coral
  static const Color accent = Color(0xFFFFC048); // sunshine
  static const Color mint = Color(0xFF55EFC4);
  static const Color sky = Color(0xFF74B9FF);
  static const Color bubblegum = Color(0xFFFD79A8);

  // ---- Semantic --------------------------------------------------------
  static const Color success = Color(0xFF00B894);
  static const Color warning = Color(0xFFFDCB6E);
  static const Color error = Color(0xFFE17055);
  static const Color info = Color(0xFF0984E3);

  // ---- Gamification currencies ----------------------------------------
  static const Color coin = Color(0xFFFFC048);
  static const Color coinDark = Color(0xFFE1A100);
  static const Color xp = Color(0xFF6C5CE7);
  static const Color gem = Color(0xFF00CEC9);
  static const Color star = Color(0xFFFFD32A);
  static const Color energy = Color(0xFFFF6B6B);

  // ---- Subject signature colors ---------------------------------------
  static const Color subjectMath = Color(0xFF6C5CE7);
  static const Color subjectEnglish = Color(0xFFFF7675);
  static const Color subjectEvs = Color(0xFF00B894);
  static const Color subjectScience = Color(0xFF0984E3);
  static const Color subjectArt = Color(0xFFFD79A8);
  static const Color subjectLogic = Color(0xFFFFA502);
  static const Color subjectRhymes = Color(0xFFE84393);

  // ---- Light surfaces --------------------------------------------------
  static const Color lightBg = Color(0xFFF6F7FF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFEFF1FB);
  static const Color lightText = Color(0xFF2D2B45);
  static const Color lightTextSoft = Color(0xFF6E6C8A);

  // ---- Dark surfaces (gentle night mode, not pure black) --------------
  static const Color darkBg = Color(0xFF191A2E);
  static const Color darkSurface = Color(0xFF23243F);
  static const Color darkSurfaceAlt = Color(0xFF2C2E4E);
  static const Color darkText = Color(0xFFF3F3FB);
  static const Color darkTextSoft = Color(0xFFB7B7D8);

  // ---- Theme gradients (backgrounds for the animated worlds) ----------
  static const List<Color> gradientSpace = [
    Color(0xFF3A1C71),
    Color(0xFF6C5CE7),
    Color(0xFF74B9FF)
  ];
  static const List<Color> gradientJungle = [
    Color(0xFF11998E),
    Color(0xFF38EF7D)
  ];
  static const List<Color> gradientOcean = [
    Color(0xFF2193B0),
    Color(0xFF6DD5ED)
  ];
  static const List<Color> gradientCandy = [
    Color(0xFFFF9A9E),
    Color(0xFFFAD0C4)
  ];
  static const List<Color> gradientSunrise = [
    Color(0xFFFFC048),
    Color(0xFFFF7675)
  ];
  static const List<Color> gradientNight = [
    Color(0xFF191A2E),
    Color(0xFF3A1C71)
  ];

  /// Color-blind-safe alternative palette (used when the accessibility
  /// setting is enabled). Chosen from Wong's colorblind-safe set.
  static const List<Color> colorBlindSafe = [
    Color(0xFF0072B2),
    Color(0xFFE69F00),
    Color(0xFF009E73),
    Color(0xFFCC79A7),
    Color(0xFFD55E00),
    Color(0xFF56B4E9),
  ];
}
