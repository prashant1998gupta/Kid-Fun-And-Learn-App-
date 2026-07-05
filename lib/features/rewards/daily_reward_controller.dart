import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gamification/domain/wallet.dart';
import '../profiles/profiles_controller.dart';
import '../settings/settings_controller.dart';

/// The 7-day daily-login reward ladder. Playing on consecutive days advances
/// the streak (and the reward); a missed day resets it. Gentle, never punitive:
/// a missed day just starts the ladder over, nothing is taken away.
class DailyReward {
  const DailyReward(this.coins, {this.gems = 0});
  final int coins;
  final int gems;
}

class DailyRewardState {
  const DailyRewardState({this.lastClaimDay, this.streak = 0});

  /// Days since epoch of the last claim (local date), or null if never claimed.
  final int? lastClaimDay;
  final int streak;

  /// 0-based index into the 7-day ladder for the *next* claim.
  int get dayIndex => streak % 7;
}

class DailyRewardController extends StateNotifier<DailyRewardState> {
  DailyRewardController(this._ref) : super(const DailyRewardState()) {
    _restore();
  }

  final Ref _ref;

  static const ladder = [
    DailyReward(10),
    DailyReward(15),
    DailyReward(20),
    DailyReward(25),
    DailyReward(30),
    DailyReward(40),
    DailyReward(60, gems: 1),
  ];

  String get _childId => _ref.read(activeChildProvider)?.id ?? '';
  String get _dayKey => 'daily_day_$_childId';
  String get _streakKey => 'daily_streak_$_childId';

  static int get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day)
        .difference(DateTime.utc(2020))
        .inDays;
  }

  void _restore() {
    final prefs = _ref.read(sharedPreferencesProvider);
    final day = prefs.getInt(_dayKey);
    state = DailyRewardState(
      lastClaimDay: day,
      streak: prefs.getInt(_streakKey) ?? 0,
    );
  }

  /// Reload for the currently active child (call after switching profiles).
  void refreshForActiveChild() => _restore();

  bool get canClaimToday => state.lastClaimDay != _today;

  /// The reward the child will get if they claim right now.
  DailyReward get pendingReward {
    final nextStreak = _computeNextStreak();
    return ladder[(nextStreak - 1) % 7];
  }

  int _computeNextStreak() {
    if (state.lastClaimDay == null) return 1;
    if (state.lastClaimDay == _today - 1) {
      return state.streak + 1; // consecutive
    }
    if (state.lastClaimDay == _today) return state.streak; // already today
    return 1; // gap → reset
  }

  /// Claim today's reward. Returns it, or null if already claimed today.
  Future<DailyReward?> claim() async {
    if (!canClaimToday) return null;
    final nextStreak = _computeNextStreak();
    final reward = ladder[(nextStreak - 1) % 7];

    // Apply coins/gems and sync the wallet's visible streak counter.
    final profiles = _ref.read(profilesControllerProvider.notifier);
    await profiles
        .applyReward(RewardBundle(coins: reward.coins, gems: reward.gems));
    await profiles.updateActive(
      (c) => c.copyWith(wallet: c.wallet.copyWith(streakDays: nextStreak)),
    );

    state = DailyRewardState(lastClaimDay: _today, streak: nextStreak);
    final prefs = _ref.read(sharedPreferencesProvider);
    await prefs.setInt(_dayKey, _today);
    await prefs.setInt(_streakKey, nextStreak);
    return reward;
  }
}

final dailyRewardControllerProvider =
    StateNotifierProvider<DailyRewardController, DailyRewardState>((ref) {
  return DailyRewardController(ref);
});
