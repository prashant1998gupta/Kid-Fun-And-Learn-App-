import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A rounded "chip" showing an amount of a currency (coins, gems, stars, XP)
/// with an icon. Animates its value with a rolling count-up whenever it
/// changes, so kids see the reward land.
class CurrencyChip extends StatelessWidget {
  const CurrencyChip({
    super.key,
    required this.icon,
    required this.value,
    required this.color,
    this.label,
  });

  final IconData icon;
  final int value;
  final Color color;
  final String? label;

  factory CurrencyChip.coins(int value) => CurrencyChip(
        icon: Icons.monetization_on_rounded,
        value: value,
        color: AppColors.coin,
      );
  factory CurrencyChip.gems(int value) => CurrencyChip(
        icon: Icons.diamond_rounded,
        value: value,
        color: AppColors.gem,
      );
  factory CurrencyChip.stars(int value) => CurrencyChip(
        icon: Icons.star_rounded,
        value: value,
        color: AppColors.star,
      );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${label ?? ''} $value',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final constrained = constraints.hasBoundedWidth;
          final compact = constrained && constraints.maxWidth < 120;
          final number = _RollingNumber(value: value, color: color);
          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? AppSpacing.sm : AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.all(AppSpacing.radiusPill),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: compact ? 22 : 26)
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      duration: 1600.ms,
                      begin: const Offset(1, 1),
                      end: const Offset(1.12, 1.12),
                    ),
                const SizedBox(width: AppSpacing.xs),
                if (constrained)
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: number,
                    ),
                  )
                else
                  number,
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Count-up number that tweens between old and new values.
class _RollingNumber extends StatelessWidget {
  const _RollingNumber({required this.value, required this.color});
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(
        v.round().toString(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
      ),
    );
  }
}

/// A horizontal XP/progress bar that fills with a satisfying spring.
class ProgressBarKid extends StatelessWidget {
  const ProgressBarKid({
    super.key,
    required this.progress,
    this.color = AppColors.xp,
    this.height = 18,
  });

  final double progress; // 0..1
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(AppSpacing.radiusPill),
      child: Stack(
        children: [
          Container(
            height: height,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress.clamp(0, 1)),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutBack,
            builder: (context, v, _) => FractionallySizedBox(
              widthFactor: v,
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.7), color],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
