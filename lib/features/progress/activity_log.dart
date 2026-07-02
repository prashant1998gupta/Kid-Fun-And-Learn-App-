import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/settings_controller.dart';

/// One child's activity on one calendar day.
class DayActivity extends Equatable {
  const DayActivity({
    required this.day,
    this.lessons = 0,
    this.stars = 0,
    this.xp = 0,
  });

  /// Epoch day index (days since 2020-01-01 UTC) — matches the streak/spin
  /// day math used elsewhere in the app.
  final int day;
  final int lessons;
  final int stars;
  final int xp;

  bool get isActive => lessons > 0;

  @override
  List<Object?> get props => [day, lessons, stars, xp];
}

/// An append-only, per-child daily activity log — the data behind the parent
/// dashboard's "over time" graphs. Kept as a pure value object (Map + methods)
/// so all the aggregation is unit-testable; the controller handles prefs I/O
/// and the game host feeds it on every lesson completion.
class ActivityLog extends Equatable {
  const ActivityLog(this._byKey);
  factory ActivityLog.empty() => const ActivityLog({});

  /// key: "childId|day" → that day's totals.
  final Map<String, DayActivity> _byKey;

  static String _key(String childId, int day) => '$childId|$day';

  /// Returns a new log with one lesson's result folded into [day].
  ActivityLog record(
    String childId,
    int day, {
    int lessons = 1,
    int stars = 0,
    int xp = 0,
  }) {
    final k = _key(childId, day);
    final cur = _byKey[k];
    final next = DayActivity(
      day: day,
      lessons: (cur?.lessons ?? 0) + lessons,
      stars: (cur?.stars ?? 0) + stars,
      xp: (cur?.xp ?? 0) + xp,
    );
    return ActivityLog({..._byKey, k: next});
  }

  /// The last [n] days ending at [today], oldest → newest, with empty days
  /// filled in as zero so charts have a continuous axis.
  List<DayActivity> lastNDays(String childId, int n, int today) {
    return [
      for (var i = n - 1; i >= 0; i--)
        _byKey[_key(childId, today - i)] ?? DayActivity(day: today - i),
    ];
  }

  int weeklyLessons(String childId, int today) =>
      lastNDays(childId, 7, today).fold(0, (s, d) => s + d.lessons);
  int weeklyStars(String childId, int today) =>
      lastNDays(childId, 7, today).fold(0, (s, d) => s + d.stars);
  int weeklyXp(String childId, int today) =>
      lastNDays(childId, 7, today).fold(0, (s, d) => s + d.xp);

  /// How many of the last 7 days had any activity.
  int activeDays(String childId, int today) =>
      lastNDays(childId, 7, today).where((d) => d.isActive).length;

  /// Consecutive active days counting back from [today] (breaks on the first
  /// gap). A lightweight streak derived purely from the log.
  int currentStreak(String childId, int today) {
    var streak = 0;
    for (var d = today; d > today - 400; d--) {
      if ((_byKey[_key(childId, d)]?.isActive ?? false)) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  Map<String, dynamic> toJson() => {
        for (final e in _byKey.entries)
          e.key: [e.value.lessons, e.value.stars, e.value.xp],
      };

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    final map = <String, DayActivity>{};
    for (final e in json.entries) {
      final day = int.tryParse(e.key.split('|').last) ?? 0;
      final v = (e.value as List?)?.cast<num>() ?? const [];
      map[e.key] = DayActivity(
        day: day,
        lessons: v.isNotEmpty ? v[0].toInt() : 0,
        stars: v.length > 1 ? v[1].toInt() : 0,
        xp: v.length > 2 ? v[2].toInt() : 0,
      );
    }
    return ActivityLog(map);
  }

  @override
  List<Object?> get props => [_byKey];
}

/// Persists and exposes the [ActivityLog]. Fed by the game host on completion;
/// read by the parent dashboard trend charts.
class ActivityController extends StateNotifier<ActivityLog> {
  ActivityController(this._ref) : super(ActivityLog.empty()) {
    _restore();
  }

  final Ref _ref;
  static const _prefsKey = 'activity_log';

  /// Epoch day index — same definition as the streak/spin day math.
  static int get today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day)
        .difference(DateTime.utc(2020))
        .inDays;
  }

  void _restore() {
    final raw = _ref.read(sharedPreferencesProvider).getString(_prefsKey);
    if (raw == null) return;
    try {
      state = ActivityLog.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      /* corrupt cache → start fresh */
    }
  }

  Future<void> record(String childId, {int stars = 0, int xp = 0}) async {
    state = state.record(childId, today, lessons: 1, stars: stars, xp: xp);
    await _ref
        .read(sharedPreferencesProvider)
        .setString(_prefsKey, jsonEncode(state.toJson()));
  }
}

final activityControllerProvider =
    StateNotifierProvider<ActivityController, ActivityLog>((ref) {
  return ActivityController(ref);
});
