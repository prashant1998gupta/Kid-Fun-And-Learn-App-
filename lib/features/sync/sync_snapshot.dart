import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A pure, Firebase-free capture of everything KidVerse persists locally, plus
/// the timestamp of the capture. This is the exact payload the [SyncService]
/// pushes to and restores from the cloud — keeping the serialization logic here
/// (with no plugin dependencies) makes the sync contract unit-testable.
///
/// Design: last-write-wins on the whole snapshot, keyed by [updatedAt]. The
/// device that saved most recently wins on the next reconcile. This mirrors the
/// offline-first stance in `docs/05_backend_architecture.md`.
class SyncSnapshot {
  const SyncSnapshot({required this.values, required this.updatedAt});

  /// Flattened prefs keyString → value (String | int | bool | List<String>).
  final Map<String, Object?> values;

  /// Epoch millis when this snapshot was captured on the source device.
  final int updatedAt;

  /// Fixed prefs keys that always exist regardless of children.
  static const _stringKeys = <String>[
    'child_profiles',
    'active_child_id',
    'lesson_progress',
    'unlocked_achievements',
    'skill_model',
    'activity_log',
    'friend_group_code',
    'locale',
  ];
  static const _intKeys = <String>['themeMode'];
  static const _boolKeys = <String>[
    'sfx',
    'music',
    'voice',
    'haptics',
    'colorBlind',
    'largeText',
  ];

  /// Per-child dynamic key templates (suffixed with the child id).
  static const _perChildIntPrefixes = <String>[
    'daily_day_',
    'daily_streak_',
    'lucky_spin_day_',
    'season_xp_',
  ];

  /// Derives the child ids from the persisted `child_profiles` blob so we can
  /// enumerate the per-child keys without reaching into other repositories.
  static List<String> childIdsFrom(SharedPreferences prefs) {
    final raw = prefs.getString('child_profiles');
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw) as List;
      return [
        for (final e in list)
          if (e is Map && e['id'] is String) e['id'] as String,
      ];
    } catch (_) {
      return const [];
    }
  }

  /// Reads the full local state into a snapshot stamped with [now] (epoch ms).
  factory SyncSnapshot.capture(SharedPreferences prefs, int now) {
    final values = <String, Object?>{};
    for (final k in _stringKeys) {
      final v = prefs.getString(k);
      if (v != null) values[k] = v;
    }
    for (final k in _intKeys) {
      final v = prefs.getInt(k);
      if (v != null) values[k] = v;
    }
    for (final k in _boolKeys) {
      final v = prefs.getBool(k);
      if (v != null) values[k] = v;
    }
    for (final id in childIdsFrom(prefs)) {
      for (final prefix in _perChildIntPrefixes) {
        final key = '$prefix$id';
        final v = prefs.getInt(key);
        if (v != null) values[key] = v;
      }
    }
    return SyncSnapshot(values: values, updatedAt: now);
  }

  /// Writes this snapshot back into local prefs. Used after a cloud pull wins.
  /// Only keys present in the snapshot are written; nothing is cleared, so a
  /// partial remote can never wipe richer local data.
  Future<void> restoreInto(SharedPreferences prefs) async {
    for (final entry in values.entries) {
      final v = entry.value;
      if (v is String) {
        await prefs.setString(entry.key, v);
      } else if (v is bool) {
        await prefs.setBool(entry.key, v);
      } else if (v is int) {
        await prefs.setInt(entry.key, v);
      } else if (v is num) {
        // Firestore may round-trip ints as doubles.
        await prefs.setInt(entry.key, v.toInt());
      }
    }
  }

  Map<String, Object?> toJson() => {'updatedAt': updatedAt, 'values': values};

  factory SyncSnapshot.fromJson(Map<String, dynamic> json) {
    final rawValues = (json['values'] as Map?)?.cast<String, Object?>() ?? {};
    return SyncSnapshot(
      values: rawValues,
      updatedAt: (json['updatedAt'] as num?)?.toInt() ?? 0,
    );
  }

  bool get isEmpty => values.isEmpty;
}
