enum SeasonRewardKind { sticker, pet, theme }

class SeasonTier {
  const SeasonTier({
    required this.level,
    required this.requiredXp,
    required this.title,
    required this.emoji,
    this.rewardKind,
    this.rewardId,
  });

  final int level;
  final int requiredXp;
  final String title;
  final String emoji;
  final SeasonRewardKind? rewardKind;
  final String? rewardId;

  bool get hasCosmetic => rewardKind != null && rewardId != null;
}

/// Cosmetic-only progression. There is no purchase path and no gameplay
/// advantage: lesson stars simply unlock profile art and world themes.
class SeasonPass {
  const SeasonPass._();

  static const title = 'Starlight Season';
  static final List<SeasonTier> tiers = List.unmodifiable(
    List.generate(50, (index) => _tier(index + 1)),
  );

  static SeasonTier _tier(int level) {
    final reward = switch (level) {
      1 => ('Crown Sticker', '👑', SeasonRewardKind.sticker, 'st_crown'),
      10 => ('Rocket Sticker', '🚀', SeasonRewardKind.sticker, 'st_rocket'),
      20 => ('Starry Night', '🌙', SeasonRewardKind.theme, 'night'),
      35 => ('Dragon Friend', '🐲', SeasonRewardKind.pet, 'pet_dragon'),
      50 => ('Aurora World', '🌌', SeasonRewardKind.theme, 'aurora'),
      _ => null,
    };
    return SeasonTier(
      level: level,
      requiredXp: level * 30,
      title: reward?.$1 ?? 'Starlight Level $level',
      emoji: reward?.$2 ?? '⭐',
      rewardKind: reward?.$3,
      rewardId: reward?.$4,
    );
  }

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
