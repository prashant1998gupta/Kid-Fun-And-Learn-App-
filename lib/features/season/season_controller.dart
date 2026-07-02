import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../profiles/profiles_controller.dart';
import '../settings/settings_controller.dart';
import 'domain/season_pass.dart';

class SeasonState {
  const SeasonState(this.xpByChild);
  final Map<String, int> xpByChild;

  int xpFor(String childId) => xpByChild[childId] ?? 0;
}

class SeasonController extends StateNotifier<SeasonState> {
  SeasonController(this._ref) : super(const SeasonState({})) {
    final prefs = _ref.read(sharedPreferencesProvider);
    final children = _ref.read(profilesControllerProvider).children;
    state = SeasonState({
      for (final child in children) child.id: prefs.getInt(_key(child.id)) ?? 0,
    });
  }

  final Ref _ref;

  static String _key(String childId) => 'season_xp_$childId';

  Future<List<SeasonTier>> recordLesson(String childId, int stars) async {
    final before = state.xpFor(childId);
    final after = before + SeasonPass.xpForStars(stars);
    final unlocked = SeasonPass.newlyUnlocked(before, after);
    state = SeasonState({...state.xpByChild, childId: after});
    await _ref.read(sharedPreferencesProvider).setInt(_key(childId), after);

    final profiles = _ref.read(profilesControllerProvider.notifier);
    for (final tier in unlocked) {
      switch (tier.rewardKind) {
        case SeasonRewardKind.sticker:
        case SeasonRewardKind.pet:
          await profiles.grantCollectible(tier.rewardId!);
        case SeasonRewardKind.theme:
          await profiles.unlockTheme(tier.rewardId!);
        case null:
          break;
      }
    }
    return unlocked;
  }
}

final seasonControllerProvider =
    StateNotifierProvider<SeasonController, SeasonState>((ref) {
  return SeasonController(ref);
});
