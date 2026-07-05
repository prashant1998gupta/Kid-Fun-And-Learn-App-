import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../profiles/profiles_controller.dart';
import '../settings/settings_controller.dart';
import 'domain/achievement.dart';

/// Tracks which achievement ids each child has unlocked, and evaluates the
/// catalog after each lesson. Newly-unlocked badges are returned so the UI can
/// celebrate them. Persisted locally; mirrors to Firestore when sync lands.
class AchievementsController extends StateNotifier<Set<String>> {
  AchievementsController(this._ref) : super({}) {
    _restore();
  }

  final Ref _ref;
  static const _key = 'unlocked_achievements';

  String get _childId => _ref.read(activeChildProvider)?.id ?? '';

  void _restore() {
    final prefs = _ref.read(sharedPreferencesProvider);
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      final map = (jsonDecode(raw) as Map).cast<String, dynamic>();
      final mine = (map[_childId] as List?)?.cast<String>() ?? const [];
      state = mine.toSet();
    } catch (_) {/* ignore corrupt cache */}
  }

  /// Reload the unlocked set for the currently active child (call on child
  /// switch so each profile shows its own badges).
  void refreshForActiveChild() => _restore();

  bool isUnlocked(String id) => state.contains(id);

  /// Evaluate the catalog against [ctx]; unlock any newly-earned badges,
  /// persist, and return them (for the celebration UI).
  Future<List<Achievement>> evaluate(AchievementContext ctx) async {
    final newly = <Achievement>[];
    for (final a in AchievementCatalog.all) {
      if (!state.contains(a.id) && a.isUnlocked(ctx)) {
        newly.add(a);
      }
    }
    if (newly.isEmpty) return const [];

    state = {...state, ...newly.map((a) => a.id)};
    await _persist();
    return newly;
  }

  Future<void> _persist() async {
    final prefs = _ref.read(sharedPreferencesProvider);
    final raw = prefs.getString(_key);
    var map = <String, dynamic>{};
    if (raw != null) {
      try {
        map = (jsonDecode(raw) as Map).cast<String, dynamic>();
      } catch (_) {
        // Replace only the corrupt achievement cache, preserving other prefs.
      }
    }
    map[_childId] = state.toList();
    await prefs.setString(_key, jsonEncode(map));
  }
}

final achievementsControllerProvider =
    StateNotifierProvider<AchievementsController, Set<String>>((ref) {
  return AchievementsController(ref);
});
