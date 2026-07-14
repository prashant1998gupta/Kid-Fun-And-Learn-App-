import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/animated_background.dart';
import '../../core/widgets/bouncy_button.dart';
import '../profiles/profiles_controller.dart';
import '../progress/activity_log.dart';

/// A printable-looking weekly certificate celebrating the active child's stars
/// this week. No sharing SDK is bundled, so the copy nudges a screenshot — the
/// natural swap point for `share_plus` later.
class CertificateScreen extends ConsumerWidget {
  const CertificateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(activeChildProvider);
    final log = ref.watch(activityControllerProvider);
    if (child == null) return const SizedBox.shrink();

    final today = ActivityController.today;
    final stars = log.weeklyStars(child.id, today);
    final lessons = log.weeklyLessons(child.id, today);
    final activeDays = log.activeDays(child.id, today);

    return Scaffold(
      body: AnimatedBackground(
        theme: WorldTheme.sunrise,
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: BouncyButton(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.primary,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: _Certificate(
                      name: child.name,
                      stars: stars,
                      lessons: lessons,
                      activeDays: activeDays,
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(
                  '📸 Screenshot to share this certificate!',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Certificate extends StatelessWidget {
  const _Certificate({
    required this.name,
    required this.stars,
    required this.lessons,
    required this.activeDays,
  });
  final String name;
  final int stars;
  final int lessons;
  final int activeDays;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppSpacing.cardRadius,
        border: Border.all(color: AppColors.accent, width: 6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 340;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🏅', style: TextStyle(fontSize: compact ? 52 : 64))
                  .animate()
                  .scale(curve: Curves.elasticOut, duration: 700.ms),
              const SizedBox(height: 8),
              Text(
                'Certificate of Achievement',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 16),
              const Text('Proudly awarded to', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 6),
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: (compact
                        ? Theme.of(context).textTheme.headlineMedium
                        : Theme.of(context).textTheme.displaySmall)
                    ?.copyWith(color: AppColors.secondary),
              ),
              const SizedBox(height: 12),
              Text(
                'for earning $stars ⭐ this week!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: compact ? 14 : 28,
                runSpacing: 10,
                children: [
                  _stat('$lessons', 'Lessons', compact: compact),
                  _stat('$stars', 'Stars', compact: compact),
                  _stat('$activeDays/7', 'Days', compact: compact),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'KidVerse • Keep learning, superstar! 🌟',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          );
        },
      ),
    ).animate().fadeIn().scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1, 1),
          curve: Curves.easeOutBack,
        );
  }

  Widget _stat(String value, String label, {required bool compact}) {
    return SizedBox(
      width: compact ? 68 : 82,
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontSize: compact ? 23 : 26,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }
}
