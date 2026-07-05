import 'package:flutter/foundation.dart';

/// Compile-time release switches supplied with `--dart-define`.
///
/// Store builds use `REQUIRE_FIREBASE=true` so a missing native Firebase
/// configuration fails during bootstrap instead of silently shipping cloud
/// buttons that cannot work. Offline QA builds intentionally leave it false.
abstract final class AppConfig {
  static const requireFirebase =
      bool.fromEnvironment('REQUIRE_FIREBASE', defaultValue: false);

  static const environment =
      String.fromEnvironment('APP_ENV', defaultValue: 'development');

  static bool get isProduction => kReleaseMode && environment == 'production';
}
