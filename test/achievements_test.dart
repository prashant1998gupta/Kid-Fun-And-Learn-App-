import 'package:flutter_test/flutter_test.dart';
import 'package:kidverse/features/achievements/domain/achievement.dart';
import 'package:kidverse/features/gamification/domain/wallet.dart';
import 'package:kidverse/features/rewards/daily_reward_controller.dart';

void main() {
  AchievementContext ctx({
    int coins = 0,
    int gems = 0,
    int xp = 0,
    int streak = 0,
    int completed = 0,
    int totalStars = 0,
    int lastStars = 0,
  }) {
    return AchievementContext(
      wallet: Wallet(coins: coins, gems: gems, xp: xp, streakDays: streak),
      completedLessons: completed,
      totalStars: totalStars,
      lastResultStars: lastStars,
    );
  }

  Achievement byId(String id) => AchievementCatalog.byId(id);

  group('Achievement predicates', () {
    test('first_steps unlocks after one lesson', () {
      expect(byId('first_steps').isUnlocked(ctx(completed: 1)), isTrue);
      expect(byId('first_steps').isUnlocked(ctx(completed: 0)), isFalse);
    });

    test('perfect needs a 3-star result', () {
      expect(byId('perfect').isUnlocked(ctx(lastStars: 3)), isTrue);
      expect(byId('perfect').isUnlocked(ctx(lastStars: 2)), isFalse);
    });

    test('rich_kid needs 100 coins', () {
      expect(byId('rich_kid').isUnlocked(ctx(coins: 100)), isTrue);
      expect(byId('rich_kid').isUnlocked(ctx(coins: 99)), isFalse);
    });

    test('level_5 needs level 5 (1000 xp)', () {
      expect(byId('level_5').isUnlocked(ctx(xp: 1000)), isTrue);
      expect(byId('level_5').isUnlocked(ctx(xp: 0)), isFalse);
    });

    test('star_master needs 30 stars', () {
      expect(byId('star_master').isUnlocked(ctx(totalStars: 30)), isTrue);
      expect(byId('star_master').isUnlocked(ctx(totalStars: 29)), isFalse);
    });

    test('catalog ids are unique', () {
      final ids = AchievementCatalog.all.map((a) => a.id).toList();
      expect(ids.toSet().length, ids.length);
    });
  });

  group('Daily reward ladder', () {
    test('has 7 rungs and the 7th grants a gem', () {
      expect(DailyRewardController.ladder.length, 7);
      expect(DailyRewardController.ladder.last.gems, 1);
      expect(DailyRewardController.ladder.first.coins, greaterThan(0));
    });
  });
}
