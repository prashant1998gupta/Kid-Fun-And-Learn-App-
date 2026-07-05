import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../settings/settings_controller.dart';
import '../domain/child_profile.dart';

/// Persists child profiles locally (offline-first). In production this mirrors
/// to Firestore under `parents/{uid}/children/{childId}`; the local store is
/// the source of truth for instant reads and offline play, with a background
/// sync reconciling the two.
class ProfilesRepository {
  ProfilesRepository(this._prefs);
  final SharedPreferences _prefs;

  static const _key = 'child_profiles';
  static const _activeKey = 'active_child_id';

  List<ChildProfile> loadAll() {
    final raw = _prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return [
        for (final entry in list)
          if (entry is Map) ChildProfile.fromMap(entry.cast<String, dynamic>()),
      ];
    } catch (_) {
      // A corrupt local cache must not prevent the app from starting.
      return [];
    }
  }

  Future<void> saveAll(List<ChildProfile> profiles) async {
    final raw = jsonEncode(profiles.map((p) => p.toMap()).toList());
    await _prefs.setString(_key, raw);
  }

  String? loadActiveId() => _prefs.getString(_activeKey);

  Future<void> saveActiveId(String? id) async {
    if (id == null) {
      await _prefs.remove(_activeKey);
    } else {
      await _prefs.setString(_activeKey, id);
    }
  }
}

final profilesRepositoryProvider = Provider<ProfilesRepository>((ref) {
  return ProfilesRepository(ref.watch(sharedPreferencesProvider));
});
