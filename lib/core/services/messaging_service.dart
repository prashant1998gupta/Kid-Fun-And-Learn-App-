import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'firebase_service.dart';

/// Push notifications for streak reminders and parent progress digests.
///
/// The client's job is narrow and privacy-safe: ask permission, register this
/// device's FCM token under the parent, and subscribe to the `streak_reminders`
/// topic. The actual reminder cadence ("come back and keep your streak!") is
/// decided and sent server-side (Cloud Functions), so no child data or
/// scheduling logic lives on-device.
///
/// Every method no-ops when Firebase isn't configured.
class MessagingService {
  MessagingService._();
  static final MessagingService instance = MessagingService._();

  static const _streakTopic = 'streak_reminders';

  String? _token;
  String? get token => _token;

  bool get _enabled => FirebaseService.instance.isAvailable;

  FirebaseMessaging get _fm => FirebaseMessaging.instance;

  /// Requests notification permission and caches the device token. Call once
  /// after Firebase init. Never throws.
  Future<void> init() async {
    if (!_enabled) return;
    try {
      await _fm.requestPermission(alert: true, badge: true, sound: true);
      _token = await _fm.getToken();
      await _fm.subscribeToTopic(_streakTopic);
      _fm.onTokenRefresh.listen((t) {
        _token = t;
        // If a parent is already signed in, the next _saveToken picks this up.
      });
    } catch (e) {
      if (kDebugMode) debugPrint('[MessagingService] disabled: $e');
    }
  }

  /// Persists the token under `parents/{uid}.fcmTokens` so the server can reach
  /// this device. Called by [AuthController] on sign-in.
  Future<void> onSignedIn(String uid) async {
    if (!_enabled || _token == null) return;
    try {
      await FirebaseFirestore.instance.collection('parents').doc(uid).set({
        'fcmTokens': FieldValue.arrayUnion([_token]),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) debugPrint('[MessagingService] token save failed: $e');
    }
  }
}
