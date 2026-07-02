import '../../gamification/domain/wallet.dart';

/// A snapshot of everything an achievement rule might inspect after a lesson.
class AchievementContext {
  const AchievementContext({
    required this.wallet,
    required this.completedLessons,
    required this.totalStars,
    required this.lastResultStars,
  });

  final Wallet wallet;
  final int completedLessons;
  final int totalStars;
  final int lastResultStars;
}

/// A badge the child can unlock. Rules are pure predicates over an
/// [AchievementContext], so the whole reward-logic surface is data + one
/// function — trivial to test and to balance.
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.isUnlocked,
    this.coinReward = 25,
  });

  final String id;
  final String title;
  final String description;
  final String emoji;
  final bool Function(AchievementContext ctx) isUnlocked;
  final int coinReward;
}

/// The full badge catalog. Ordered easiest → hardest for the badges grid.
class AchievementCatalog {
  const AchievementCatalog._();

  static final List<Achievement> all = [
    Achievement(
      id: 'first_steps',
      title: 'First Steps',
      description: 'Finish your first lesson',
      emoji: '👣',
      isUnlocked: (c) => c.completedLessons >= 1,
    ),
    Achievement(
      id: 'perfect',
      title: 'Perfect!',
      description: 'Earn 3 stars in a game',
      emoji: '🌟',
      isUnlocked: (c) => c.lastResultStars >= 3,
    ),
    Achievement(
      id: 'star_collector',
      title: 'Star Collector',
      description: 'Collect 10 stars',
      emoji: '⭐',
      coinReward: 40,
      isUnlocked: (c) => c.totalStars >= 10,
    ),
    Achievement(
      id: 'explorer',
      title: 'Explorer',
      description: 'Finish 5 lessons',
      emoji: '🧭',
      coinReward: 40,
      isUnlocked: (c) => c.completedLessons >= 5,
    ),
    Achievement(
      id: 'rich_kid',
      title: 'Treasure Hunter',
      description: 'Save up 100 coins',
      emoji: '💰',
      coinReward: 50,
      isUnlocked: (c) => c.wallet.coins >= 100,
    ),
    Achievement(
      id: 'gem_hunter',
      title: 'Gem Hunter',
      description: 'Find 3 gems',
      emoji: '💎',
      coinReward: 50,
      isUnlocked: (c) => c.wallet.gems >= 3,
    ),
    Achievement(
      id: 'level_5',
      title: 'Rising Star',
      description: 'Reach level 5',
      emoji: '🏅',
      coinReward: 60,
      isUnlocked: (c) => c.wallet.level >= 5,
    ),
    Achievement(
      id: 'streak_3',
      title: 'On Fire',
      description: 'Play 3 days in a row',
      emoji: '🔥',
      coinReward: 60,
      isUnlocked: (c) => c.wallet.streakDays >= 3,
    ),
    Achievement(
      id: 'star_master',
      title: 'Star Master',
      description: 'Collect 30 stars',
      emoji: '👑',
      coinReward: 100,
      isUnlocked: (c) => c.totalStars >= 30,
    ),
  ];

  static Achievement byId(String id) =>
      all.firstWhere((a) => a.id == id, orElse: () => all.first);
}
