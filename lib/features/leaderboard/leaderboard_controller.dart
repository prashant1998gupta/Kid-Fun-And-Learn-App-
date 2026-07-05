import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../profiles/profiles_controller.dart';
import '../progress/activity_log.dart';
import '../settings/settings_controller.dart';
import 'data/leaderboard_api.dart';
import 'domain/leaderboard_entry.dart';

/// Holds the family's joined friend-group code (or null) and pushes the active
/// child's weekly score to it. The code is stored locally (and rides the sync
/// snapshot), so a group survives restarts and follows the family across
/// devices.
class LeaderboardController extends StateNotifier<String?> {
  LeaderboardController(this._ref) : super(null) {
    state = _ref.read(sharedPreferencesProvider).getString(_prefsKey);
  }

  final Ref _ref;
  static const _prefsKey = 'friend_group_code';

  LeaderboardApi get _api => _ref.read(leaderboardApiProvider);

  bool get hasGroup => (state ?? '').isNotEmpty;

  /// Join (or create — same thing) a group by shared code, then publish.
  Future<void> joinGroup(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return;
    state = normalized;
    await _ref.read(sharedPreferencesProvider).setString(_prefsKey, normalized);
    await publish();
  }

  Future<void> leaveGroup() async {
    state = null;
    await _ref.read(sharedPreferencesProvider).remove(_prefsKey);
  }

  /// Pushes the active child's weekly stars to the current group. No-op if not
  /// signed in, no group, or offline.
  Future<void> publish() async {
    final code = state;
    final uid = _ref.read(authControllerProvider).account?.uid;
    final child = _ref.read(activeChildProvider);
    if (code == null || code.isEmpty || uid == null || child == null) return;

    final score = _ref.read(activityControllerProvider).weeklyStars(
          child.id,
          ActivityController.today,
        );
    await _api.publishScore(
      uid,
      groupCode: code,
      displayName: child.name,
      avatarSeed: AvatarSeed.encode(child.avatar),
      score: score,
    );
  }
}

final leaderboardControllerProvider =
    StateNotifierProvider<LeaderboardController, String?>((ref) {
  return LeaderboardController(ref);
});

/// Live entries for a given group code (empty when offline).
final leaderboardEntriesProvider =
    StreamProvider.family<List<LeaderboardEntry>, String>((ref, code) {
  return ref.watch(leaderboardApiProvider).entries(code);
});
