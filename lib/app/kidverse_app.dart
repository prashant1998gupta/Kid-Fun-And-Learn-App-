import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../core/services/audio_service.dart';
import '../core/widgets/kid_experience_layer.dart';
import '../features/auth/auth_controller.dart';
import '../features/profiles/profiles_controller.dart';
import '../features/settings/settings_controller.dart';
import '../l10n/app_localizations.dart';
import 'router.dart';

/// Root widget. Wires theme, routing and the media-query text-scale override
/// for the "large text" accessibility setting.
class KidVerseApp extends ConsumerWidget {
  const KidVerseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final router = ref.watch(routerProvider);
    final energyLevel = ref.watch(
            activeChildProvider.select((child) => child?.energyMode.index)) ??
        1;
    AudioService.instance.configureEnergy(energyLevel);

    // Eagerly create the auth session so a returning signed-in parent triggers
    // a background cloud sync on launch (no-op when offline).
    ref.watch(authControllerProvider);

    return MaterialApp.router(
      title: 'KidVerse',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode,
      locale: Locale(settings.locale),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
      builder: (context, child) {
        final scale = settings.largeText ? 1.25 : 1.0;
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: settings.reducedMotion,
          ),
          child: MediaQuery.withClampedTextScaling(
            minScaleFactor: scale,
            maxScaleFactor: scale * 1.3,
            child: KidExperienceLayer(
              reducedMotion: settings.reducedMotion,
              energyLevel: energyLevel,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}
