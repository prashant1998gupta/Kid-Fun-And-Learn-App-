import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/animated_background.dart';
import '../../core/widgets/bouncy_button.dart';
import 'achievements_controller.dart';
import 'domain/achievement.dart';

/// The trophy room: every badge in the catalog, unlocked ones in full color,
/// locked ones dimmed with a padlock and a hint of how to earn them.
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlocked = ref.watch(achievementsControllerProvider);
    final all = AchievementCatalog.all;
    final earned = unlocked.length;

    return Scaffold(
      body: AnimatedBackground(
        theme: WorldTheme.sunrise,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    BouncyButton(
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
                    const SizedBox(width: 12),
                    Text(
                      'My Badges',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(color: Colors.white),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(AppSpacing.radiusPill),
                      ),
                      child: Text(
                        '$earned / ${all.length}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: all.length,
                  itemBuilder: (context, i) => _BadgeCard(
                    achievement: all[i],
                    unlocked: unlocked.contains(all[i].id),
                  ).animate().fadeIn(delay: (60 * i).ms).scale(
                        begin: const Offset(0.9, 0.9),
                        end: const Offset(1, 1),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.achievement, required this.unlocked});
  final Achievement achievement;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: unlocked ? Colors.white : Colors.white.withValues(alpha: 0.35),
        borderRadius: AppSpacing.cardRadius,
        boxShadow: unlocked
            ? [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (unlocked)
            Text(achievement.emoji, style: const TextStyle(fontSize: 52))
          else
            const Icon(Icons.lock_rounded, size: 44, color: Colors.white),
          const SizedBox(height: 8),
          Text(
            achievement.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: unlocked ? AppColors.lightText : Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            achievement.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: unlocked ? AppColors.lightTextSoft : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
