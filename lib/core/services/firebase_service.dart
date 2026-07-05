import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';

/// Boots Firebase and gates the whole cloud layer behind a single availability
/// flag.
///
/// KidVerse is offline-first by design: the app is fully playable with no
/// backend. Firebase only lights up once real platform config
/// (`google-services.json` / `GoogleService-Info.plist`)
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

  /// Attempts to bring Firebase online. A missing/invalid config leaves normal
  /// offline builds offline; `REQUIRE_FIREBASE=true` release builds throw so a
  /// broken store artifact cannot be produced silently.
  Future<void> init() async {
    if (_available) return;
    try {
      // With no generated `firebase_options.dart`, this reads the native
      // google-services config. Absent that, it throws — which we swallow.
      await Firebase.initializeApp();
      _available = true;
    } catch (e) {
      _available = false;
      if (kDebugMode) {
        debugPrint('[FirebaseService] Cloud disabled (offline mode): $e');
      }
      if (AppConfig.requireFirebase) rethrow;
    }
  }
}
