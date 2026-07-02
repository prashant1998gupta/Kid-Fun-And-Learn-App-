import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/firebase_service.dart';
import '../domain/leaderboard_entry.dart';

/// Client surface for the friends leaderboard.
///
/// Split of responsibility (see `firebase/firestore.rules`):
/// - The client WRITES its own weekly score to its `parents/{uid}` doc — a path
///   it already owns, so no new rules are needed.
/// - A Cloud Function fans those into `leaderboards/{code}/entries` (server
///   write, which bypasses rules and keeps the board tamper-proof).
/// - The client only READS `leaderboards/{code}/entries` (authed read allowed).
///
/// Every method degrades to a safe no-op / empty stream when Firebase is
/// offline, so the leaderboard screen still renders a friendly empty state.
class LeaderboardApi {
  LeaderboardApi(this._firebase);
  final FirebaseService _firebase;

  bool get _enabled => _firebase.isAvailable;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Publishes the active child's weekly score into the family's own doc. The
  /// aggregator function reads this and updates the shared board.
  Future<void> publishScore(
    String uid, {
    required String groupCode,
    required String displayName,
    required String avatarSeed,
    required int score,
  }) async {
    if (!_enabled) return;
    try {
      await _db.collection('parents').doc(uid).set({
        'friendGroup': {
          'code': groupCode,
          'displayName': displayName,
          'avatarSeed': avatarSeed,
          'score': score,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));
    } catch (_) {
      /* publishing is best-effort; never block the UI */
    }
  }

  /// Live top-N entries for a group, ranked by score desc. Empty when offline.
  Stream<List<LeaderboardEntry>> entries(String groupCode, {int limit = 50}) {
    if (!_enabled || groupCode.isEmpty) {
      return Stream.value(const <LeaderboardEntry>[]);
    }
    return _db
        .collection('leaderboards')
        .doc(groupCode)
        .collection('entries')
        .orderBy('score', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) {
      var rank = 0;
      return [
        for (final doc in snap.docs)
          LeaderboardEntry.fromMap(doc.id, doc.data()).copyWith(rank: ++rank),
      ];
    });
  }
}

final leaderboardApiProvider = Provider<LeaderboardApi>((ref) {
  return LeaderboardApi(FirebaseService.instance);
});
