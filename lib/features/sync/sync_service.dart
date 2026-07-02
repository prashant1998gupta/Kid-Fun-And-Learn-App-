import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/firebase_service.dart';
import '../settings/settings_controller.dart';
import 'sync_snapshot.dart';

/// Mirrors the offline-first local store to Firestore under `parents/{uid}`.
///
/// Reconcile policy (v1, honest about its limits):
/// - Cloud is a **backup + cross-device restore**, never the live source.
/// - A device that already has play data always wins — we push it up, so a
///   returning player can't be silently overwritten by stale cloud data.
/// - A **fresh** device (no local children) hydrates itself from the cloud.
/// Fine-grained per-field multi-device merge is deferred to P2; last-write-wins
/// on the whole snapshot is enough while a family shares one device.
///
/// Every method is a safe no-op when Firebase isn't configured.
class SyncService {
  SyncService(this._prefs);
  final SharedPreferences _prefs;

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  bool get _enabled => FirebaseService.instance.isAvailable;

  DocumentReference<Map<String, dynamic>> _parentDoc(String uid) =>
      _db.collection('parents').doc(uid);

  /// Pushes the current local state to the cloud. Also projects each child into
  /// the `children` subcollection (one-way) so future server reports and the
  /// schema in `docs/05_backend_architecture.md` have structured data to read.
  Future<void> push(String uid, int now) async {
    if (!_enabled) return;
    final snapshot = SyncSnapshot.capture(_prefs, now);
    await _parentDoc(uid).set({
      'updatedAt': FieldValue.serverTimestamp(),
      'deviceState': snapshot.toJson(),
    }, SetOptions(merge: true));
    await _projectChildren(uid);
  }

  /// Reads the cloud snapshot, or null when none exists / offline.
  Future<SyncSnapshot?> pull(String uid) async {
    if (!_enabled) return null;
    final doc = await _parentDoc(uid).get();
    final data = doc.data();
    final device = data?['deviceState'];
    if (device is! Map) return null;
    final snapshot = SyncSnapshot.fromJson(device.cast<String, dynamic>());
    return snapshot.isEmpty ? null : snapshot;
  }

  /// Reconciles local and cloud on sign-in. Returns which way data flowed.
  Future<SyncOutcome> reconcile(String uid, int now) async {
    if (!_enabled) return SyncOutcome.skipped;
    final remote = await pull(uid);
    final localHasData = SyncSnapshot.childIdsFrom(_prefs).isNotEmpty;

    // Nothing in the cloud yet → seed it from this device.
    if (remote == null) {
      await push(uid, now);
      return SyncOutcome.pushed;
    }
    // Fresh device, cloud has a backup → hydrate locally.
    if (!localHasData) {
      await remote.restoreInto(_prefs);
      return SyncOutcome.pulled;
    }
    // Both have data → this active device wins; refresh the cloud backup.
    await push(uid, now);
    return SyncOutcome.pushed;
  }

  /// Writes each child profile to `parents/{uid}/children/{childId}` for
  /// server-side reporting. Best-effort — a failure here never blocks a push.
  Future<void> _projectChildren(String uid) async {
    final raw = _prefs.getString('child_profiles');
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List;
      final batch = _db.batch();
      final col = _parentDoc(uid).collection('children');
      for (final e in list) {
        if (e is! Map || e['id'] is! String) continue;
        batch.set(
          col.doc(e['id'] as String),
          {...e.cast<String, dynamic>(), 'syncedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true),
        );
      }
      await batch.commit();
    } catch (_) {
      /* projection is non-critical; the deviceState blob is the real backup */
    }
  }
}

enum SyncOutcome { pushed, pulled, skipped }

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref.watch(sharedPreferencesProvider));
});
