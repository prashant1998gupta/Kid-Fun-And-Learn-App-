import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/kidverse_app.dart';
import 'core/services/audio_service.dart';
import 'core/services/firebase_service.dart';
import 'core/services/messaging_service.dart';
import 'features/settings/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait + landscape both supported (responsive), matching the spec.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Bring the cloud layer online if this build has Firebase config. Both calls
  // no-op safely when it's absent — the app is fully functional offline.
  await FirebaseService.instance.init();
  await MessagingService.instance.init();

  final prefs = await SharedPreferences.getInstance();
  await AudioService.instance.init();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const KidVerseApp(),
    ),
  );
}
