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

  /// Removes a child profile by [id]. If the removed child was the active one,
  /// the next available child (or none) becomes active.
  Future<void> removeChild(String id) async {
    final remaining = state.children.where((c) => c.id != id).toList();
    final newActive = state.activeId == id
        ? (remaining.isNotEmpty ? remaining.first.id : null)
        : state.activeId;
    state = ProfilesState(children: remaining, activeId: newActive);
    await _persist();
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

  /// Adds a collectible to the active child. Returns true if it was new, false
  /// if already owned (so the caller can hand out a duplicate refund).
  Future<bool> grantCollectible(String id) async {
    final active = state.active;
    if (active == null) return false;
    if (active.ownedCollectibles.contains(id)) return false;
    _replace(active.copyWith(
      ownedCollectibles: [...active.ownedCollectibles, id],
    ));
    await _persist();
    return true;
  }

  /// Equips a pet companion (must already be owned).
  Future<void> setActivePet(String petId) async {
    final active = state.active;
    if (active == null || !active.ownedCollectibles.contains(petId)) return;
    _replace(active.copyWith(activePetId: petId));
    await _persist();
  }

  Future<int> addCompanionXp(int amount, {String? memory}) async {
    final active = state.active;
    if (active == null) return 0;
    final nextXp = active.companionXp + amount.clamp(0, 1000);
    _replace(active.copyWith(
      companionXp: nextXp,
      companionMemory: memory,
      lastActiveAt: DateTime.now(),
    ));
    await _persist();
    return nextXp;
  }

  /// Migrates older feature-local pet progress without ever moving the shared
  /// companion backwards.
  Future<int> syncCompanionXp(int targetXp, {String? memory}) async {
    final active = state.active;
    if (active == null) return targetXp;
    final nextXp =
        targetXp > active.companionXp ? targetXp : active.companionXp;
    _replace(active.copyWith(
      companionXp: nextXp,
      companionMemory: memory,
      lastActiveAt: DateTime.now(),
    ));
    await _persist();
    return nextXp;
  }

  Future<void> renameCompanion(String name) async {
    final clean = name.trim();
    if (clean.isEmpty) return;
    await updateActive((child) => child.copyWith(
          companionName: clean,
          companionMemory: 'I love my new name, $clean!',
        ));
  }

  Future<bool> grantRoomItem(String itemId) async {
    final active = state.active;
    if (active == null || active.ownedRoomItems.contains(itemId)) return false;
    _replace(active.copyWith(
      ownedRoomItems: [...active.ownedRoomItems, itemId],
      placedRoomItems: [...active.placedRoomItems, itemId],
    ));
    await _persist();
    return true;
  }

  Future<void> toggleRoomItem(String itemId) async {
    final active = state.active;
    if (active == null || !active.ownedRoomItems.contains(itemId)) return;
    final placed = [...active.placedRoomItems];
    if (placed.contains(itemId)) {
      placed.remove(itemId);
    } else {
      placed.add(itemId);
    }
    _replace(active.copyWith(placedRoomItems: placed));
    await _persist();
  }

  Future<void> chooseDrawingHero(String drawingId, String name) async {
    await updateActive(
      (child) => child.copyWith(heroDrawingId: drawingId, heroName: name),
    );
  }

  Future<void> rememberAdventure({required bool neededHelp}) async {
    await updateActive((child) {
      final memory = neededHelp
          ? 'That was tricky, but we kept trying together!'
          : 'You solved that adventure so confidently!';
      return child.copyWith(
        companionMemory: memory,
        completedAdventures: child.completedAdventures + 1,
        lastActiveAt: DateTime.now(),
      );
    });
  }

  Future<void> setEnergyMode(KidEnergyMode mode) async {
    await updateActive((child) => child.copyWith(
          energyMode: mode,
          companionMemory: switch (mode) {
            KidEnergyMode.calm =>
              'We can learn softly and take our time today.',
            KidEnergyMode.ready =>
              'We are ready for a bright learning adventure!',
            KidEnergyMode.active =>
              'Zoom! Let us mix learning with movement today!',
          },
        ));
  }

  Future<void> setSiblingCoop(bool enabled) async {
    await updateActive((child) => child.copyWith(
          siblingCoopEnabled: enabled,
          companionMemory: enabled
              ? 'Team mode is ready. Helping each other is a superpower!'
              : 'Solo mode is ready. I will be your teammate!',
        ));
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
