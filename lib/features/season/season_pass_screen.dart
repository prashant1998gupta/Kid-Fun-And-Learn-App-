import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/audio_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/animated_background.dart';
import '../../core/widgets/bouncy_button.dart';
import '../profiles/profiles_controller.dart';
import '../profiles/domain/child_profile.dart';
import 'domain/season_pass.dart';
import 'season_controller.dart';

class SeasonPassScreen extends ConsumerWidget {
  const SeasonPassScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(activeChildProvider);
    if (child == null) return const SizedBox.shrink();
    final xp = ref.watch(seasonControllerProvider).xpFor(child.id);
    final next = SeasonPass.nextTier(xp);

    return Scaffold(
      body: AnimatedBackground(
        theme: WorldTheme.aurora,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    BouncyButton(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: const CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(Icons.arrow_back_rounded),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        SeasonPass.title,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(color: Colors.white),
                      ),
                    ),
                    Text('✨ $xp XP',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: SeasonPass.progress(xp),
                      minHeight: 16,
                      borderRadius:
                          const BorderRadius.all(AppSpacing.radiusPill),
                      backgroundColor: Colors.white24,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(AppColors.star),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      next == null
                          ? 'Season complete! Every cosmetic is yours.'
                          : '${next.requiredXp - xp} XP to ${next.title}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: SeasonPass.tiers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final tier = SeasonPass.tiers[index];
                    final unlocked = xp >= tier.requiredXp;
                    return _TierCard(
                      tier: tier,
                      unlocked: unlocked,
                      equipped: _isEquipped(child, tier),
                      onEquip: unlocked ? () => _equip(ref, tier) : null,
                    ).animate().fadeIn(delay: (70 * index).ms).slideX(
                          begin: 0.08,
                          end: 0,
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

  bool _isEquipped(ChildProfile child, SeasonTier tier) {
    return switch (tier.rewardKind) {
      SeasonRewardKind.theme => child.activeTheme == tier.rewardId,
      SeasonRewardKind.pet => child.activePetId == tier.rewardId,
      SeasonRewardKind.sticker => false,
    };
  }

  Future<void> _equip(WidgetRef ref, SeasonTier tier) async {
    final profiles = ref.read(profilesControllerProvider.notifier);
    switch (tier.rewardKind) {
      case SeasonRewardKind.theme:
        await profiles.setActiveTheme(tier.rewardId);
      case SeasonRewardKind.pet:
        await profiles.setActivePet(tier.rewardId);
      case SeasonRewardKind.sticker:
        return;
    }
    AudioService.instance.playSfx(Sfx.unlock);
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard({
    required this.tier,
    required this.unlocked,
    required this.equipped,
    required this.onEquip,
  });

  final SeasonTier tier;
  final bool unlocked;
  final bool equipped;
  final VoidCallback? onEquip;

  @override
  Widget build(BuildContext context) {
    final canEquip = tier.rewardKind != SeasonRewardKind.sticker;
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: unlocked ? Colors.white : Colors.white.withValues(alpha: 0.18),
        borderRadius: AppSpacing.cardRadius,
        border: Border.all(color: Colors.white54, width: 2),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: unlocked ? AppColors.primary : Colors.white24,
            child: Text('${tier.level}',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 14),
          Text(tier.emoji, style: const TextStyle(fontSize: 38)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tier.title,
                    style: TextStyle(
                        color: unlocked ? AppColors.lightText : Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 17)),
                Text('${tier.requiredXp} XP',
                    style: TextStyle(
                        color: unlocked
                            ? AppColors.lightTextSoft
                            : Colors.white70)),
              ],
            ),
          ),
          if (!unlocked)
            const Icon(Icons.lock_rounded, color: Colors.white70)
          else if (canEquip)
            TextButton(
              onPressed: equipped ? null : onEquip,
              child: Text(equipped ? 'Equipped' : 'Equip'),
            )
          else
            const Icon(Icons.check_circle_rounded, color: AppColors.success),
        ],
      ),
    );
  }
}
