import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/widgets/animated_background.dart';
import '../../core/widgets/mascot.dart';
import '../profiles/profiles_controller.dart';

/// Animated splash: mascot pops in, wordmark rises, then routes onward based on
/// whether any child profile exists.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _bootTimer;

  @override
  void initState() {
    super.initState();
    _bootTimer = Timer(const Duration(milliseconds: 2200), _boot);
  }

  void _boot() {
    if (!mounted) return;
    final profiles = ref.read(profilesControllerProvider);
    if (profiles.hasProfiles) {
      context.go(AppRoutes.profilePicker);
    } else {
      context.go(AppRoutes.onboarding);
    }
  }

  @override
  void dispose() {
    _bootTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        theme: WorldTheme.space,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                constraints.maxWidth < 360 || constraints.maxHeight < 560;
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MascotView(mascot: Mascot.owl, size: compact ? 140 : 180)
                        .animate()
                        .scale(
                          duration: 700.ms,
                          curve: Curves.elasticOut,
                          begin: const Offset(0.3, 0.3),
                          end: const Offset(1, 1),
                        ),
                    SizedBox(height: compact ? 18 : 24),
                    Text(
                      'KidVerse',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: (compact
                              ? Theme.of(context).textTheme.displayMedium
                              : Theme.of(context).textTheme.displayLarge)
                          ?.copyWith(color: Colors.white),
                    )
                        .animate()
                        .fadeIn(delay: 400.ms)
                        .slideY(begin: 0.4, end: 0),
                    const SizedBox(height: 8),
                    Text(
                      'Play. Learn. Grow.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: Colors.white70),
                    ).animate().fadeIn(delay: 900.ms),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
