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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    final profiles = ref.read(profilesControllerProvider);
    if (profiles.hasProfiles) {
      context.go(AppRoutes.profilePicker);
    } else {
      context.go(AppRoutes.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        theme: WorldTheme.space,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MascotView(mascot: Mascot.owl, size: 180).animate().scale(
                    duration: 700.ms,
                    curve: Curves.elasticOut,
                    begin: const Offset(0.3, 0.3),
                    end: const Offset(1, 1),
                  ),
              const SizedBox(height: 24),
              Text(
                'KidVerse',
                style: Theme.of(context)
                    .textTheme
                    .displayLarge
                    ?.copyWith(color: Colors.white),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.4, end: 0),
              const SizedBox(height: 8),
              Text(
                'Play. Learn. Grow.',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: Colors.white70),
              ).animate().fadeIn(delay: 900.ms),
            ],
          ),
        ),
      ),
    );
  }
}
