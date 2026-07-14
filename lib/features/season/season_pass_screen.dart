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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 360;
                    return Row(
                      children: [
                        BouncyButton(
                          onTap: () => Navigator.of(context).maybePop(),
                          child: CircleAvatar(
                            radius: compact ? 18 : 20,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.arrow_back_rounded,
                              color: AppColors.primary,
                              size: compact ? 22 : 24,
                            ),
                          ),
                        ),
                        SizedBox(width: compact ? 8 : 12),
                        Expanded(
                          child: Text(
                            SeasonPass.title,
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
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              '✨ $xp XP',
                              maxLines: 1,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: compact ? 15 : 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
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
      SeasonRewardKind.theme => child.activeTheme == tier.rewardId!,
      SeasonRewardKind.pet => child.activePetId == tier.rewardId!,
      SeasonRewardKind.sticker => false,
      null => false,
    };
  }

  Future<void> _equip(WidgetRef ref, SeasonTier tier) async {
    if (!tier.hasCosmetic) return;
    final profiles = ref.read(profilesControllerProvider.notifier);
    switch (tier.rewardKind) {
      case SeasonRewardKind.theme:
        await profiles.setActiveTheme(tier.rewardId!);
      case SeasonRewardKind.pet:
        await profiles.setActivePet(tier.rewardId!);
      case SeasonRewardKind.sticker:
        return;
      case null:
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
    final canEquip = tier.rewardKind == SeasonRewardKind.theme ||
        tier.rewardKind == SeasonRewardKind.pet;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        return Container(
          padding: compact ? const EdgeInsets.all(14) : AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color:
                unlocked ? Colors.white : Colors.white.withValues(alpha: 0.18),
            borderRadius: AppSpacing.cardRadius,
            border: Border.all(color: Colors.white54, width: 2),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: compact ? 22 : 26,
                backgroundColor: unlocked ? AppColors.primary : Colors.white24,
                child: Text(
                  '${tier.level}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              SizedBox(width: compact ? 10 : 14),
              Text(tier.emoji, style: TextStyle(fontSize: compact ? 32 : 38)),
              SizedBox(width: compact ? 9 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tier.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: unlocked ? AppColors.lightText : Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: compact ? 15 : 17,
                      ),
                    ),
                    Text(
                      '${tier.requiredXp} XP',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                            unlocked ? AppColors.lightTextSoft : Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: compact ? 6 : 8),
              if (!unlocked)
                Icon(
                  Icons.lock_rounded,
                  color: Colors.white70,
                  size: compact ? 22 : 24,
                )
              else if (canEquip)
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: TextButton(
                      onPressed: equipped ? null : onEquip,
                      child: Text(equipped ? 'Equipped' : 'Equip'),
                    ),
                  ),
                )
              else if (tier.hasCosmetic)
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: compact ? 22 : 24,
                ),
            ],
          ),
        );
      },
    );
  }
}
