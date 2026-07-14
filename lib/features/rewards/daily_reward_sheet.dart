import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/audio_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bouncy_button.dart';
import 'daily_reward_controller.dart';

/// Shows the daily-reward ladder in a bottom sheet and lets the child claim
/// today's gift. Call [showDailyRewardSheet].
Future<void> showDailyRewardSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (_) => const DailyRewardSheet(),
  );
}

class DailyRewardSheet extends ConsumerStatefulWidget {
  const DailyRewardSheet({super.key});

  @override
  ConsumerState<DailyRewardSheet> createState() => _DailyRewardSheetState();
}

class _DailyRewardSheetState extends ConsumerState<DailyRewardSheet> {
  bool _claimedNow = false;

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(dailyRewardControllerProvider.notifier);
    ref.watch(dailyRewardControllerProvider); // rebuild on claim
    final canClaim = controller.canClaimToday;
    const ladder = DailyRewardController.ladder;
    final nextIndex = (_pendingStreak(controller) - 1) % 7;
    final media = MediaQuery.of(context);
    final compact = media.size.width < 360 || media.textScaler.scale(1) > 1.2;
    final columns = media.size.width < 360 ? 3 : 4;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg + media.viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🎁', style: TextStyle(fontSize: compact ? 42 : 56))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: -4, end: 4, duration: 1000.ms),
            const SizedBox(height: 8),
            Text(
              'Daily Gift',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              canClaim ? 'Tap to claim your reward!' : 'Come back tomorrow! 🌙',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: columns,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              childAspectRatio: compact ? 1.05 : 0.9,
              children: [
                for (int i = 0; i < ladder.length; i++)
                  _DayTile(
                    day: i + 1,
                    reward: ladder[i],
                    isNext: canClaim && i == nextIndex,
                    claimed: !canClaim && i == nextIndex,
                    compact: compact,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            BouncyButton(
              onTap: (canClaim && !_claimedNow)
                  ? () async {
                      final reward = await controller.claim();
                      if (reward == null) return;
                      setState(() => _claimedNow = true);
                      AudioService.instance.playSfx(Sfx.reward);
                      AudioService.instance.speak('You got a daily gift!');
                      await Future<void>.delayed(
                        const Duration(milliseconds: 900),
                      );
                      if (context.mounted) Navigator.of(context).pop();
                    }
                  : null,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: compact ? 13 : 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: canClaim
                        ? [AppColors.success, AppColors.mint]
                        : [Colors.grey, Colors.grey.shade400],
                  ),
                  borderRadius: const BorderRadius.all(AppSpacing.radiusPill),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    canClaim ? 'Claim Gift!' : 'Claimed Today',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 18 : 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  int _pendingStreak(DailyRewardController c) {
    // Mirror controller logic for display without exposing internals.
    final s = ref.read(dailyRewardControllerProvider);
    if (s.lastClaimDay == null) return 1;
    return c.canClaimToday ? s.streak + 1 : s.streak;
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({
    required this.day,
    required this.reward,
    required this.isNext,
    required this.claimed,
    required this.compact,
  });

  final int day;
  final DailyReward reward;
  final bool isNext;
  final bool claimed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final highlight = isNext;
    return Container(
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.accent.withValues(alpha: 0.25)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.all(AppSpacing.radiusMd),
        border:
            highlight ? Border.all(color: AppColors.accent, width: 3) : null,
      ),
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: EdgeInsets.all(compact ? 4 : 6),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Day $day',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: compact ? 10 : 12,
                      ),
                    ),
                    SizedBox(height: compact ? 1 : 2),
                    Text(
                      reward.gems > 0 ? '💎' : '🪙',
                      style: TextStyle(fontSize: compact ? 17 : 22),
                    ),
                    Text(
                      reward.gems > 0 ? '${reward.gems}' : '${reward.coins}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.coinDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (claimed)
            Positioned(
              top: compact ? 2 : 4,
              right: compact ? 2 : 4,
              child: Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: compact ? 13 : 16,
              ),
            ),
        ],
      ),
    );
  }
}
