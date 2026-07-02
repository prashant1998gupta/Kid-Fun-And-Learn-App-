import 'package:flutter/widgets.dart';

/// 4-pt spacing scale + kid-friendly sizing tokens.
///
/// Touch targets are intentionally large: minimum 64dp (well above the 48dp
/// Material minimum) because small children have developing motor control.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  /// Minimum interactive target for a child's fingertip.
  static const double minTouchTarget = 64;

  // Corner radii — everything is soft and rounded.
  static const Radius radiusSm = Radius.circular(12);
  static const Radius radiusMd = Radius.circular(20);
  static const Radius radiusLg = Radius.circular(28);
  static const Radius radiusXl = Radius.circular(40);
  static const Radius radiusPill = Radius.circular(999);

  static const BorderRadius cardRadius = BorderRadius.all(radiusLg);
  static const BorderRadius buttonRadius = BorderRadius.all(radiusPill);
  static const BorderRadius sheetRadius = BorderRadius.vertical(top: radiusXl);

  static const EdgeInsets screenPadding = EdgeInsets.all(md);
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
}
