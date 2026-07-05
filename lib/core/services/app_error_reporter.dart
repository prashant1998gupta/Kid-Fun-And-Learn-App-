import 'package:flutter/foundation.dart';

/// Central boundary for uncaught framework, platform, and zone errors.
///
/// Production output intentionally contains only the exception type so child
/// profile data can never leak into device logs. A consent-aware crash backend
/// can be connected here later without changing app bootstrap code.
abstract final class AppErrorReporter {
  static void record(Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      debugPrint('[KidVerse] Unhandled error: $error\n$stackTrace');
    } else {
      debugPrint('[KidVerse] Unhandled ${error.runtimeType}');
    }
  }
}
