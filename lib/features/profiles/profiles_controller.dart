import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../gamification/domain/wallet.dart';
import 'data/profiles_repository.dart';
import 'domain/child_profile.dart';
import 'domain/grade_level.dart';

/// Holds all children under the current parent account and which one is active.
class ProfilesState {
  const ProfilesState({this.children = const [], this.activeId});

  final List<ChildProfile> children;
  final String? activeId;

  ChildProfile? get active {
    if (activeId == null) return null;
    for (final c in children) {
      if (c.id == activeId) return c;
    }
    return children.isEmpty ? null : children.first;
  }

  bool get hasProfiles => children.isNotEmpty;

  ProfilesState copyWith({List<ChildProfile>? children, String? activeId}) {
    return ProfilesState(
      children: children ?? this.children,
      activeId: activeId ?? this.activeId,
    );
  }
}

class ProfilesController extends StateNotifier<ProfilesState> {
  ProfilesController(this._repo) : super(const ProfilesState()) {
    _restore();
  }

  final ProfilesRepository _repo;
  final _uuid = const Uuid();

  void _restore() {
    final children = _repo.loadAll();
    state = ProfilesState(children: children, activeId: _repo.loadActiveId());
  }

  Future<ChildProfile> addChild({
    required String name,
    required GradeLevel grade,
    required AvatarConfig avatar,
    String mascotId = 'panda',
  }) async {
    final child = ChildProfile(
      id: _uuid.v4(),
      name: name,
      grade: grade,
      avatar: avatar,
      mascotId: mascotId,
      createdAt: DateTime.now(),
      lastActiveAt: DateTime.now(),
    );
    final updated = [...state.children, child];
    state = state.copyWith(children: updated, activeId: child.id);
    await _persist();
    return child;
  }

  Future<void> selectChild(String id) async {
    state = state.copyWith(activeId: id);
    await _repo.saveActiveId(id);
  }

  Future<void> updateActive(ChildProfile Function(ChildProfile) mutate) async {
    final active = state.active;
    if (active == null) return;
    final updated = mutate(active);
    _replace(updated);
    await _persist();
  }

  /// Applies a [RewardBundle] to the active child and returns the new wallet
  /// (so the UI can animate the deltas).
  Future<Wallet> applyReward(RewardBundle reward) async {
    final active = state.active;
    if (active == null) return const Wallet();
    final w = active.wallet;
    final next = w.copyWith(
      coins: w.coins + reward.coins,
      gems: w.gems + reward.gems,
      stars: w.stars + reward.stars,
      xp: w.xp + reward.xp,
    );
    _replace(active.copyWith(wallet: next, lastActiveAt: DateTime.now()));
    await _persist();
    return next;
  }

  /// Attempts to spend [cost] coins from the active child. Returns true on
  /// success, false if they can't afford it (no partial spends).
  Future<bool> spendCoins(int cost) async {
    final active = state.active;
    if (active == null || active.wallet.coins < cost) return false;
    _replace(active.copyWith(
      wallet: active.wallet.copyWith(coins: active.wallet.coins - cost),
    ));
    await _persist();
    return true;
  }

  /// Unlocks a world theme (adds it to the child's unlocked list).
  Future<void> unlockTheme(String themeId) async {
    final active = state.active;
    if (active == null || active.unlockedThemes.contains(themeId)) return;
    _replace(active.copyWith(
      unlockedThemes: [...active.unlockedThemes, themeId],
    ));
    await _persist();
  }

  /// Sets the child's active world theme.
  Future<void> setActiveTheme(String themeId) async {
    final active = state.active;
    if (active == null) return;
    _replace(active.copyWith(activeTheme: themeId));
    await _persist();
  }

  void _replace(ChildProfile updated) {
    final list = [
      for (final c in state.children)
        if (c.id == updated.id) updated else c,
    ];
    state = state.copyWith(children: list);
  }

  Future<void> _persist() async {
    await _repo.saveAll(state.children);
    await _repo.saveActiveId(state.activeId);
  }
}

final profilesControllerProvider =
    StateNotifierProvider<ProfilesController, ProfilesState>((ref) {
  return ProfilesController(ref.watch(profilesRepositoryProvider));
});

/// Convenience: the active child (or null).
final activeChildProvider = Provider<ChildProfile?>((ref) {
  return ref.watch(profilesControllerProvider).active;
});
