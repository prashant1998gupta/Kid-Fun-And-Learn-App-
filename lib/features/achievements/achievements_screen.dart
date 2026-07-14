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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 360;
                    return Row(
                      children: [
                        BouncyButton(
                          onTap: () => Navigator.of(context).maybePop(),
                          child: Container(
                            padding: EdgeInsets.all(compact ? 8 : 10),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_back_rounded,
                              color: AppColors.primary,
                              size: compact ? 23 : 26,
                            ),
                          ),
                        ),
                        SizedBox(width: compact ? 8 : 12),
                        Expanded(
                          child: Text(
                            'My Badges',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: (compact
                                    ? Theme.of(context).textTheme.titleLarge
                                    : Theme.of(context)
                                        .textTheme
                                        .headlineMedium)
                                ?.copyWith(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: compact ? 11 : 14,
                            vertical: compact ? 7 : 8,
                          ),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.all(AppSpacing.radiusPill),
                          ),
                          child: Text(
                            '$earned / ${all.length}',
                            maxLines: 1,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              fontSize: compact ? 14 : 16,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 360;
                    return GridView.builder(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: compact ? 170 : 200,
                        mainAxisSpacing: AppSpacing.md,
                        crossAxisSpacing: AppSpacing.md,
                        childAspectRatio: compact ? 0.72 : 0.85,
                      ),
                      itemCount: all.length,
                      itemBuilder: (context, i) => _BadgeCard(
                        achievement: all[i],
                        unlocked: unlocked.contains(all[i].id),
                      ).animate().fadeIn(delay: (60 * i).ms).scale(
                            begin: const Offset(0.9, 0.9),
                            end: const Offset(1, 1),
                          ),
                    );
                  },
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final tight = constraints.maxHeight < 195;
        return Container(
          padding: EdgeInsets.all(tight ? AppSpacing.sm : AppSpacing.md),
          decoration: BoxDecoration(
            color:
                unlocked ? Colors.white : Colors.white.withValues(alpha: 0.35),
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
                Text(
                  achievement.emoji,
                  style: TextStyle(fontSize: tight ? 42 : 52),
                )
              else
                Icon(
                  Icons.lock_rounded,
                  size: tight ? 36 : 44,
                  color: Colors.white,
                ),
              SizedBox(height: tight ? 6 : 8),
              Flexible(
                child: Text(
                  achievement.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: tight ? 14 : 16,
                    height: 1.05,
                    color: unlocked ? AppColors.lightText : Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  achievement.description,
                  maxLines: tight ? 3 : 4,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: tight ? 11 : 12,
                    height: 1.1,
                    color: unlocked ? AppColors.lightTextSoft : Colors.white70,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
