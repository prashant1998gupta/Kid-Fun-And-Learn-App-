import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../curriculum/domain/subject.dart';
import '../gamification/reward_engine.dart';
import '../settings/settings_controller.dart';

/// Lightweight on-device adaptive-learning model.
///
/// It maintains a per-(child, subject) *skill estimate* in [0,1] using an
/// exponential moving average of mastery, and a per-question "struggle" tally
/// to power weak-area detection and smart revision. This runs fully offline and
/// privacy-preserving; aggregate signals can later sync to Firestore to feed a
/// server-side recommendation engine, but nothing here requires the network.
class SkillModel {
  SkillModel({Map<String, double>? skills, Map<String, int>? struggles})
      : _skills = skills ?? {},
        _struggles = struggles ?? {};

  final Map<String, double> _skills; // key: "childId|subject"
  final Map<String, int> _struggles; // key: "childId|questionId"

  static const _alpha = 0.35; // EMA responsiveness

  double skillFor(String childId, Subject subject) =>
      _skills['$childId|${subject.name}'] ?? 0.4; // start "still learning"

  /// Fold a completed lesson into the model.
  void observe(String childId, LessonResult result) {
    final key = '$childId|${result.lesson.subject.name}';
    final prev = _skills[key] ?? 0.4;
    _skills[key] = prev * (1 - _alpha) + result.mastery * _alpha;

    for (final qid in result.struggledQuestionIds) {
      final sk = '$childId|$qid';
      _struggles[sk] = (_struggles[sk] ?? 0) + 1;
    }
  }

  /// The subjects where the child is weakest (skill below [threshold]),
  /// most-weak first — drives "Recommended practice" and parent reports.
  List<Subject> weakAreas(String childId, {double threshold = 0.55}) {
    final scored = <MapEntry<Subject, double>>[];
    for (final s in Subject.values) {
      final v = skillFor(childId, s);
      if (v < threshold) scored.add(MapEntry(s, v));
    }
    scored.sort((a, b) => a.value.compareTo(b.value));
    return scored.map((e) => e.key).toList();
  }

  List<Subject> strengths(String childId, {double threshold = 0.75}) {
    return [
      for (final s in Subject.values)
        if (skillFor(childId, s) >= threshold) s,
    ];
  }

  /// Recommended difficulty offset for the next lesson in a subject.
  /// Returns a delta to apply on top of the child's grade tier:
  /// -1 (ease off), 0 (hold), +1 (push) — the heart of difficulty adjustment.
  int difficultyDelta(String childId, Subject subject) {
    final v = skillFor(childId, subject);
    if (v >= 0.85) return 1;
    if (v < 0.4) return -1;
    return 0;
  }

  /// Questions the child repeatedly missed — feeds Smart Revision.
  List<String> revisionQuestionIds(String childId, {int min = 2}) {
    final prefix = '$childId|';
    return [
      for (final e in _struggles.entries)
        if (e.key.startsWith(prefix) && e.value >= min)
          e.key.substring(prefix.length),
    ];
  }

  Map<String, dynamic> toMap() => {'skills': _skills, 'struggles': _struggles};

  factory SkillModel.fromMap(Map<String, dynamic> m) => SkillModel(
        skills: (m['skills'] as Map?)
                ?.map((k, v) => MapEntry(k as String, (v as num).toDouble())) ??
            {},
        struggles: (m['struggles'] as Map?)
                ?.map((k, v) => MapEntry(k as String, (v as num).toInt())) ??
            {},
      );
}

/// Persists and exposes the [SkillModel].
class AdaptiveController extends StateNotifier<SkillModel> {
  AdaptiveController(this._prefs) : super(_restore(_prefs));

  final SharedPreferences _prefs;
  static const _key = 'skill_model';

  static SkillModel _restore(SharedPreferences prefs) {
    final raw = prefs.getString(_key);
    if (raw == null) return SkillModel();
    try {
      return SkillModel.fromMap(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return SkillModel();
    }
  }

  Future<void> record(String childId, LessonResult result) async {
    state.observe(childId, result);
    // Re-emit a fresh instance so listeners rebuild.
    state = SkillModel.fromMap(state.toMap());
    await _prefs.setString(_key, jsonEncode(state.toMap()));
  }
}

final adaptiveControllerProvider =
    StateNotifierProvider<AdaptiveController, SkillModel>((ref) {
  return AdaptiveController(ref.watch(sharedPreferencesProvider));
});
