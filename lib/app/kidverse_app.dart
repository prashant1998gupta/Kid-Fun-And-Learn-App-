import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../features/settings/settings_controller.dart';
import 'router.dart';

/// Root widget. Wires theme, routing and the media-query text-scale override
/// for the "large text" accessibility setting.
class KidVerseApp extends ConsumerWidget {
  const KidVerseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'KidVerse',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode,
      routerConfig: router,
      builder: (context, child) {
        final scale = settings.largeText ? 1.25 : 1.0;
        return MediaQuery.withClampedTextScaling(
          minScaleFactor: scale,
          maxScaleFactor: scale * 1.3,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
