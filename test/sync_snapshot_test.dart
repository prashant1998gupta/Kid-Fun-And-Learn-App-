import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidverse/features/sync/sync_snapshot.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The sync contract is the [SyncSnapshot] serializer. These tests exercise it
/// with no Firebase in the loop: capture → JSON → restore must be lossless, and
/// per-child dynamic keys must be enumerated from the profile blob.
void main() {
  const childId = 'child-abc';
  final profiles = jsonEncode([
    {'id': childId, 'name': 'Mia', 'grade': 'ukg'},
  ]);

  Map<String, Object> seed() => {
        'child_profiles': profiles,
        'active_child_id': childId,
        'lesson_progress': jsonEncode({'$childId|l1': 3}),
        'unlocked_achievements': jsonEncode({'first_steps': 1}),
        'skill_model': jsonEncode({'math': 0.7}),
        'locale': 'en',
        'themeMode': 2,
        'sfx': false,
        'music': true,
        'colorBlind': true,
        // Per-child dynamic keys.
        'daily_day_$childId': 20200,
        'daily_streak_$childId': 5,
        'lucky_spin_day_$childId': 20200,
        'season_xp_$childId': 140,
      };

  test('childIdsFrom reads ids out of the profiles blob', () async {
    SharedPreferences.setMockInitialValues({'child_profiles': profiles});
    final prefs = await SharedPreferences.getInstance();
    expect(SyncSnapshot.childIdsFrom(prefs), [childId]);
  });

  test('capture picks up fixed, settings, and per-child keys', () async {
    SharedPreferences.setMockInitialValues(seed());
    final prefs = await SharedPreferences.getInstance();

    final snap = SyncSnapshot.capture(prefs, 111);
    expect(snap.updatedAt, 111);
    expect(snap.values['active_child_id'], childId);
    expect(snap.values['themeMode'], 2);
    expect(snap.values['sfx'], false);
    expect(snap.values['daily_streak_$childId'], 5);
    expect(snap.values['lucky_spin_day_$childId'], 20200);
    expect(snap.values['season_xp_$childId'], 140);
    // Absent keys stay absent (never written as null).
    expect(snap.values.containsKey('haptics'), isFalse);
  });

  test('capture → JSON → restore is lossless', () async {
    SharedPreferences.setMockInitialValues(seed());
    final source = await SharedPreferences.getInstance();
    final captured = SyncSnapshot.capture(source, 222);

    // Round-trip through JSON as it would through Firestore.
    final json =
        jsonDecode(jsonEncode(captured.toJson())) as Map<String, dynamic>;
    final remote = SyncSnapshot.fromJson(json);

    // Restore into a *fresh* device.
    SharedPreferences.setMockInitialValues({});
    final target = await SharedPreferences.getInstance();
    await remote.restoreInto(target);

    expect(target.getString('active_child_id'), childId);
    expect(target.getString('lesson_progress'), jsonEncode({'$childId|l1': 3}));
    expect(target.getInt('themeMode'), 2);
    expect(target.getBool('sfx'), false);
    expect(target.getBool('colorBlind'), true);
    expect(target.getInt('daily_streak_$childId'), 5);
    expect(target.getInt('lucky_spin_day_$childId'), 20200);
    expect(target.getInt('season_xp_$childId'), 140);
  });

  test('restore never clears keys missing from the snapshot', () async {
    // A partial remote (only settings) must not wipe richer local data.
    const remote = SyncSnapshot(values: {'themeMode': 1}, updatedAt: 1);
    SharedPreferences.setMockInitialValues({
      'child_profiles': profiles,
      'lesson_progress': jsonEncode({'$childId|l1': 2}),
    });
    final prefs = await SharedPreferences.getInstance();
    await remote.restoreInto(prefs);

    expect(prefs.getInt('themeMode'), 1);
    expect(prefs.getString('lesson_progress'), jsonEncode({'$childId|l1': 2}));
  });

  test('num values round-trip back to int (Firestore double coercion)',
      () async {
    const remote = SyncSnapshot(
      values: {'daily_streak_$childId': 7.0},
      updatedAt: 1,
    );
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await remote.restoreInto(prefs);
    expect(prefs.getInt('daily_streak_$childId'), 7);
  });
}
