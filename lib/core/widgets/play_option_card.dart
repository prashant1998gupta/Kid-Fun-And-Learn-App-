import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'bouncy_button.dart';
import 'illustrated_object.dart';

/// The visual state of an answer tile in a "pick the right one" game.
enum PlayCardState { idle, correct, wrong }

/// The shared, delightful answer tile used across the grid-based learning games
/// (tap-choice, listen-and-tap, …). One source of truth for the feel:
/// - a soft top-lit gradient + white border + colored glow (never a flat fill);
/// - a staggered "pop-in" as each question's options appear;
/// - a gentle idle float, each tile on its own phase, so the board feels alive
///   (suppressed when the OS "reduce motion" setting is on);
/// - a green pulse when right, a red shake when wrong.
class PlayOptionCard extends StatelessWidget {
  const PlayOptionCard({
    super.key,
    required this.index,
    required this.label,
    required this.state,
    required this.onTap,
    this.emoji,
    this.artSize,
  });

  /// Position in the option list — drives the entrance/float stagger.
  final int index;
  final String label;
  final String? emoji;
  final PlayCardState state;
  final VoidCallback onTap;

  /// Optional override for the illustration size.
  final double? artSize;

  @override
  Widget build(BuildContext context) {
    final isIdle = state == PlayCardState.idle;
    final fg = isIdle ? AppColors.lightText : Colors.white;
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    final gradient = switch (state) {
      PlayCardState.correct => const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.success, AppColors.mint],
        ),
      PlayCardState.wrong => LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.error, AppColors.error.withValues(alpha: 0.82)],
        ),
      PlayCardState.idle => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFF2EFFF)],
        ),
    };
    final glow = switch (state) {
      PlayCardState.correct => AppColors.success.withValues(alpha: 0.5),
      PlayCardState.wrong => AppColors.error.withValues(alpha: 0.45),
      PlayCardState.idle => AppColors.primary.withValues(alpha: 0.16),
    };
    final size = artSize ?? (emoji == null ? 58 : 72);
    final effectiveArtSize =
        (textScale > 1.25 ? size * 0.82 : size).clamp(42.0, size).toDouble();

    Widget inner = Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: AppSpacing.cardRadius,
        border: Border.all(
          color: isIdle ? Colors.white : Colors.white.withValues(alpha: 0.75),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: glow,
            blurRadius: isIdle ? 16 : 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IllustratedObjectView(
              label: label,
              emoji: emoji,
              size: effectiveArtSize,
              selected: !isIdle,
            ),
            if (emoji != null) ...[
              SizedBox(height: textScale > 1.25 ? 4 : 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(color: fg),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (isIdle && !MediaQuery.disableAnimationsOf(context)) {
      inner = inner.animate(onPlay: (c) => c.repeat(reverse: true)).moveY(
            begin: 0,
            end: -6,
            duration: (1500 + index * 130).ms,
            curve: Curves.easeInOut,
          );
    }

    Widget card = BouncyButton(
      borderRadius: AppSpacing.cardRadius,
      onTap: onTap,
      child: inner,
    );

    if (state == PlayCardState.wrong) {
      card = card.animate().shake(
            hz: 6,
            rotation: 0,
            offset: const Offset(10, 0),
            duration: 400.ms,
          );
    } else if (state == PlayCardState.correct) {
      card = card
          .animate()
          .scale(begin: const Offset(1, 1), end: const Offset(1.08, 1.08))
          .then()
          .scale(begin: const Offset(1.08, 1.08), end: const Offset(1, 1));
    } else {
      card =
          card.animate().fadeIn(duration: 260.ms, delay: (index * 70).ms).scale(
                begin: const Offset(0.82, 0.82),
                end: const Offset(1, 1),
                delay: (index * 70).ms,
                duration: 320.ms,
                curve: Curves.easeOutBack,
              );
    }
    return card;
  }
}
