import 'package:flutter_test/flutter_test.dart';
import 'package:kidverse/features/season/domain/season_pass.dart';

void main() {
  test('lesson stars convert to bounded season XP', () {
    expect(SeasonPass.xpForStars(1), 10);
    expect(SeasonPass.xpForStars(3), 30);
    expect(SeasonPass.xpForStars(99), 30);
  });

  test('newlyUnlocked returns only crossed tiers', () {
    final unlocked = SeasonPass.newlyUnlocked(60, 140);
    expect(unlocked.map((tier) => tier.level), [2, 3]);
  });

  test('progress resets between tiers and completes at the cap', () {
    expect(SeasonPass.progress(0), 0);
    expect(SeasonPass.progress(30), 0);
    expect(SeasonPass.progress(50), closeTo(0.5, 0.001));
    expect(SeasonPass.progress(350), 1);
  });

  test('every season reward id is stable and unique', () {
    final ids = SeasonPass.tiers.map((tier) => tier.rewardId).toSet();
    expect(ids.length, SeasonPass.tiers.length);
  });
}
