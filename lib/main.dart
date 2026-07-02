import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/kidverse_app.dart';
import 'core/services/audio_service.dart';
import 'features/settings/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait + landscape both supported (responsive), matching the spec.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Firebase.initializeApp() goes here once google-services files are added.
  // The app is fully functional offline without it, by design.

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
