import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/services/audio_service.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/animated_background.dart';
import '../../core/widgets/bouncy_button.dart';
import '../../core/widgets/mascot.dart';

/// Three-page welcome carousel. Minimal reading, big visuals, voice narration
/// on each page — sets the tone before the parent creates a profile.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    _OnbData(
      mascot: Mascot.panda,
      theme: WorldTheme.candy,
      title: 'Welcome to KidVerse!',
      body: 'A magical world where playing is learning.',
      voice: 'Welcome to KidVerse! A magical world where playing is learning.',
    ),
    _OnbData(
      mascot: Mascot.unicorn,
      theme: WorldTheme.jungle,
      title: 'Play Fun Games',
      body: 'Earn coins, stars and shiny rewards!',
      voice: 'Play fun games and earn coins, stars and shiny rewards!',
    ),
    _OnbData(
      mascot: Mascot.robot,
      theme: WorldTheme.ocean,
      title: 'Grow Every Day',
      body: 'Your buddies will cheer you on!',
      voice: 'Grow every day. Your buddies will cheer you on!',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => AudioService.instance.speak(_pages[0].voice),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      context.go(AppRoutes.profileCreate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _pages.length,
            onPageChanged: (i) {
              setState(() => _page = i);
              AudioService.instance.speak(_pages[i].voice);
            },
            itemBuilder: (_, i) => _OnboardingPage(data: _pages[i]),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < _pages.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        width: i == _page ? 28 : 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.white
                              .withValues(alpha: i == _page ? 1 : 0.5),
                          borderRadius:
                              const BorderRadius.all(AppSpacing.radiusPill),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                BouncyButton(
                  onTap: _next,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 18,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppSpacing.buttonRadius,
                    ),
                    child: Text(
                      _page == _pages.length - 1 ? "Let's Go!" : 'Next',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 50,
            right: 20,
            child: TextButton(
              onPressed: () => context.go(AppRoutes.profileCreate),
              child: const Text(
                'Skip',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnbData {
  const _OnbData({
    required this.mascot,
    required this.theme,
    required this.title,
    required this.body,
    required this.voice,
  });
  final Mascot mascot;
  final WorldTheme theme;
  final String title;
  final String body;
  final String voice;
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data});
  final _OnbData data;

  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      theme: data.theme,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MascotView(mascot: data.mascot, size: 200)
                .animate()
                .scale(curve: Curves.elasticOut, duration: 600.ms),
            const SizedBox(height: 40),
            Text(
              data.title,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .displayMedium
                  ?.copyWith(color: Colors.white),
            ).animate().fadeIn().slideY(begin: 0.3, end: 0),
            const SizedBox(height: 16),
            Text(
              data.body,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Colors.white),
            ).animate().fadeIn(delay: 200.ms),
          ],
        ),
      ),
    );
  }
}
