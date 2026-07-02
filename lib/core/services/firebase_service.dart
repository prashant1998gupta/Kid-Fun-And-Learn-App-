import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Boots Firebase and gates the whole cloud layer behind a single availability
/// flag.
///
/// KidVerse is offline-first by design: the app is fully playable with no
/// backend. Firebase only lights up once real platform config
/// (`google-services.json` / `GoogleService-Info.plist` / `firebase_options.dart`)
/// is present. Until then — and whenever init fails on a device — [isAvailable]
/// stays `false` and every cloud call (auth, sync, messaging) becomes a safe
/// no-op instead of a crash.
class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  bool _available = false;

  /// True only after a successful [Firebase.initializeApp]. Every cloud
  /// service checks this before touching a Firebase plugin.
  bool get isAvailable => _available;

  FirebaseAnalytics? _analytics;

  /// Analytics handle, or null when Firebase isn't configured.
  FirebaseAnalytics? get analytics => _analytics;

  /// Attempts to bring Firebase online. Never throws: a missing/invalid config
  /// simply leaves the app in offline mode. Safe to call once from `main()`.
  Future<void> init() async {
    if (_available) return;
    try {
      // With no generated `firebase_options.dart`, this reads the native
      // google-services config. Absent that, it throws — which we swallow.
      await Firebase.initializeApp();
      _analytics = FirebaseAnalytics.instance;
      _available = true;
    } catch (e) {
      _available = false;
      if (kDebugMode) {
        debugPrint('[FirebaseService] Cloud disabled (offline mode): $e');
      }
    }
  }

  /// Logs an analytics event, silently ignored when offline. Never sends child
  /// PII — callers pass only aggregate, non-identifying parameters.
  Future<void> logEvent(String name, [Map<String, Object>? params]) async {
    if (!_available) return;
    try {
      await _analytics?.logEvent(name: name, parameters: params);
    } catch (_) {
      /* analytics must never break a play session */
    }
  }
}
