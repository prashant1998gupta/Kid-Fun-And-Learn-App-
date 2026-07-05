import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/kidverse_app.dart';
import 'core/config/app_config.dart';
import 'core/services/audio_service.dart';
import 'core/services/app_error_reporter.dart';
import 'core/services/firebase_service.dart';
import 'core/services/messaging_service.dart';
import 'features/settings/settings_controller.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      AppErrorReporter.record(
        details.exception,
        details.stack ?? StackTrace.current,
      );
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      AppErrorReporter.record(error, stack);
      return true;
    };
    ErrorWidget.builder = (details) => const ColoredBox(
          color: Color(0xFFFFF8F0),
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Something went wrong. Please ask a grown-up to restart KidVerse.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        );

    try {
      // Portrait + landscape both supported (responsive), matching the spec.
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);

      // Cloud and notifications remain optional for offline builds.
      final prefs = await SharedPreferences.getInstance();

      await Future.wait([
        _initializeCloud(),
        AudioService.instance.init().catchError((_) {}),
      ]);
      await MessagingService.instance.init(
        parentEnabled: prefs.getBool('notificationsEnabled') ?? false,
      );

      runApp(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const KidVerseApp(),
        ),
      );
    } catch (error, stackTrace) {
      AppErrorReporter.record(error, stackTrace);
      runApp(const _BootstrapFailureApp());
    }
  }, AppErrorReporter.record);
}

Future<void> _initializeCloud() async {
  try {
    await FirebaseService.instance.init().timeout(const Duration(seconds: 8));
  } catch (error, stackTrace) {
    AppErrorReporter.record(error, stackTrace);
    if (AppConfig.requireFirebase) rethrow;
  }
}

class _BootstrapFailureApp extends StatelessWidget {
  const _BootstrapFailureApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFFFFF8F0),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🛠️', style: TextStyle(fontSize: 64)),
                  SizedBox(height: 16),
                  Text(
                    'KidVerse could not start safely.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please ask a grown-up to close and reopen the app.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
