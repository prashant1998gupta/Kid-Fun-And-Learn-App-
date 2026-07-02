import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../profiles/profiles_controller.dart';
import '../settings/settings_controller.dart';

/// Per-child, per-lesson progress: the best star score (0–3) a child has earned
/// on each lesson. Drives the Learning Map (node state, unlocking, the reward
/// chest) and feeds richer parent reports. Persisted locally (offline-first);
/// mirrors to Firestore `children/{id}/progress` when cloud sync lands.
class ProgressState {
  const ProgressState(this.starsByLesson);

  /// key: "childId|lessonId" → best stars (1..3)
  final Map<String, int> starsByLesson;

  int starsFor(String childId, String lessonId) =>
      starsByLesson['$childId|$lessonId'] ?? 0;

  bool isCompleted(String childId, String lessonId) =>
      starsFor(childId, lessonId) > 0;

  int totalStars(String childId) {
    final prefix = '$childId|';
    var sum = 0;
    for (final e in starsByLesson.entries) {
      if (e.key.startsWith(prefix)) sum += e.value;
    }
    return sum;
  }
}

class ProgressController extends StateNotifier<ProgressState> {
  ProgressController(this._ref) : super(const ProgressState({})) {
    _restore();
  }

  final Ref _ref;
  static const _key = 'lesson_progress';

  void _restore() {
    final prefs = _ref.read(sharedPreferencesProvider);
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      final map = (jsonDecode(raw) as Map)
          .map((k, v) => MapEntry(k as String, (v as num).toInt()));
      state = ProgressState(map);
    } catch (_) {
      /* corrupt cache → start fresh */
    }
  }

  /// Records a lesson result. Only upgrades the stored score (best-ever kept),
  /// so replaying can improve but never lower a child's stars.
  Future<void> recordStars(String lessonId, int stars) async {
    final child = _ref.read(activeChildProvider);
    if (child == null) return;
    final key = '${child.id}|$lessonId';
    final best = state.starsByLesson[key] ?? 0;
    if (stars <= best) return;

    final next = Map<String, int>.from(state.starsByLesson)..[key] = stars;
    state = ProgressState(next);

    final prefs = _ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, jsonEncode(next));
  }
}

final progressControllerProvider =
    StateNotifierProvider<ProgressController, ProgressState>((ref) {
  return ProgressController(ref);
});
