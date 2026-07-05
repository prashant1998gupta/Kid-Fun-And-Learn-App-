import 'dart:async';

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
  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _initialized = false;
  String? _signedInUid;

  bool get _enabled => FirebaseService.instance.isAvailable;

  FirebaseMessaging get _fm => FirebaseMessaging.instance;

  /// Initializes messaging only when a parent has already opted in. A fresh
  /// install never sees a notification prompt during child-facing startup.
  Future<bool> init({required bool parentEnabled}) async {
    if (!_enabled || !parentEnabled) return false;
    return setEnabled(true);
  }

  /// Applies the parent-controlled notification preference.
  Future<bool> setEnabled(bool enabled, {String? uid}) async {
    if (!_enabled) return false;
    try {
      if (!enabled) {
        final previousToken = _token;
        if (uid != null && previousToken != null) {
          await _removeToken(uid, previousToken);
        }
        await _fm.unsubscribeFromTopic(_streakTopic);
        await _fm.deleteToken();
        await _tokenRefreshSubscription?.cancel();
        _tokenRefreshSubscription = null;
        _token = null;
        _initialized = false;
        _signedInUid = null;
        return true;
      }

      await _fm.requestPermission(alert: true, badge: true, sound: true);
      final settings = await _fm.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return false;
      }
      _token = await _fm.getToken();
      if (_token == null) return false;
      await _fm.subscribeToTopic(_streakTopic);
      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = _fm.onTokenRefresh.listen((t) {
        _token = t;
        final uid = _signedInUid;
        if (uid != null) unawaited(onSignedIn(uid));
      });
      _initialized = true;
      if (uid != null) await onSignedIn(uid);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[MessagingService] disabled: $e');
      return false;
    }
  }

  /// Persists the token under `parents/{uid}.fcmTokens` so the server can reach
  /// this device. Called by [AuthController] on sign-in.
  Future<void> onSignedIn(String uid) async {
    if (!_enabled || !_initialized || _token == null) return;
    _signedInUid = uid;
    try {
      await FirebaseFirestore.instance.collection('parents').doc(uid).set({
        'fcmTokens': FieldValue.arrayUnion([_token]),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) debugPrint('[MessagingService] token save failed: $e');
    }
  }

  Future<void> _removeToken(String uid, String token) async {
    try {
      await FirebaseFirestore.instance.collection('parents').doc(uid).set({
        'fcmTokens': FieldValue.arrayRemove([token]),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) debugPrint('[MessagingService] token removal failed: $e');
    }
  }
}
