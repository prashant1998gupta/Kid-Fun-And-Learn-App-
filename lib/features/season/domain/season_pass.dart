enum SeasonRewardKind { sticker, pet, theme }

class SeasonTier {
  const SeasonTier({
    required this.level,
    required this.requiredXp,
    required this.title,
    required this.emoji,
    required this.rewardKind,
    required this.rewardId,
  });

  final int level;
  final int requiredXp;
  final String title;
  final String emoji;
  final SeasonRewardKind rewardKind;
  final String rewardId;
}

/// Cosmetic-only progression. There is no purchase path and no gameplay
/// advantage: lesson stars simply unlock profile art and world themes.
class SeasonPass {
  const SeasonPass._();

  static const title = 'Starlight Season';
  static const tiers = <SeasonTier>[
    SeasonTier(
      level: 1,
      requiredXp: 30,
      title: 'Crown Sticker',
      emoji: '👑',
      rewardKind: SeasonRewardKind.sticker,
      rewardId: 'st_crown',
    ),
    SeasonTier(
      level: 2,
      requiredXp: 70,
      title: 'Rocket Sticker',
      emoji: '🚀',
      rewardKind: SeasonRewardKind.sticker,
      rewardId: 'st_rocket',
    ),
    SeasonTier(
      level: 3,
      requiredXp: 130,
      title: 'Starry Night',
      emoji: '🌙',
      rewardKind: SeasonRewardKind.theme,
      rewardId: 'night',
    ),
    SeasonTier(
      level: 4,
      requiredXp: 220,
      title: 'Dragon Friend',
      emoji: '🐲',
      rewardKind: SeasonRewardKind.pet,
      rewardId: 'pet_dragon',
    ),
    SeasonTier(
      level: 5,
      requiredXp: 350,
      title: 'Aurora World',
      emoji: '🌌',
      rewardKind: SeasonRewardKind.theme,
      rewardId: 'aurora',
    ),
  ];

  static int xpForStars(int stars) => stars.clamp(1, 3) * 10;

  static List<SeasonTier> unlockedAt(int xp) =>
      tiers.where((tier) => xp >= tier.requiredXp).toList();

  static List<SeasonTier> newlyUnlocked(int before, int after) => tiers
      .where((tier) => before < tier.requiredXp && after >= tier.requiredXp)
      .toList();

  static SeasonTier? nextTier(int xp) {
    for (final tier in tiers) {
      if (xp < tier.requiredXp) return tier;
    }
    return null;
  }

  static double progress(int xp) {
    final next = nextTier(xp);
    if (next == null) return 1;
    final previous = next.level == 1 ? 0 : tiers[next.level - 2].requiredXp;
    return ((xp - previous) / (next.requiredXp - previous)).clamp(0, 1);
  }
}
