import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/firebase_service.dart';
import '../achievements/achievements_controller.dart';
import '../ai/adaptive_engine.dart';
import '../auth/domain/parent_account.dart';
import '../profiles/profiles_controller.dart';
import '../progress/progress_controller.dart';
import '../rewards/daily_reward_controller.dart';
import '../settings/settings_controller.dart';
import '../spin/lucky_spin_controller.dart';
import 'sync_service.dart';

enum SyncStatus { idle, syncing, synced, offline, error }

class SyncState {
  const SyncState({
    this.status = SyncStatus.idle,
    this.lastSyncedAt,
    this.message,
  });

  final SyncStatus status;
  final DateTime? lastSyncedAt;
  final String? message;

  SyncState copyWith({
    SyncStatus? status,
    DateTime? lastSyncedAt,
    String? message,
  }) {
    return SyncState(
      status: status ?? this.status,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      message: message,
    );
  }
}

/// Drives cloud sync and, after a cloud pull, refreshes every persisted
/// controller by invalidating its provider — each re-restores from prefs on
/// rebuild, so no controller needs a bespoke "reload" method.
class SyncController extends StateNotifier<SyncState> {
  SyncController(this._ref) : super(const SyncState());

  final Ref _ref;
  String? _uid;

  SyncService get _service => _ref.read(syncServiceProvider);

  int get _now => DateTime.now().millisecondsSinceEpoch;

  /// Called by [AuthController] whenever the session changes.
  Future<void> onAccountChanged(ParentAccount? account) async {
    _uid = account?.uid;
    if (account == null) {
      state = const SyncState(status: SyncStatus.idle);
      return;
    }
    await _reconcile();
  }

  Future<void> _reconcile() async {
    final uid = _uid;
    if (uid == null) return;
    if (!FirebaseService.instance.isAvailable) {
      state = state.copyWith(status: SyncStatus.offline);
      return;
    }
    state = state.copyWith(status: SyncStatus.syncing, message: null);
    try {
      final outcome = await _service.reconcile(uid, _now);
      if (outcome == SyncOutcome.pulled) _refreshLocalControllers();
      state =
          SyncState(status: SyncStatus.synced, lastSyncedAt: DateTime.now());
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        message: 'Sync failed — your progress is safe on this device.',
      );
    }
  }

  /// Manual "Sync now" from the parent dashboard: pushes local up.
  Future<void> pushNow() async {
    final uid = _uid;
    if (uid == null || !FirebaseService.instance.isAvailable) {
      state = state.copyWith(status: SyncStatus.offline);
      return;
    }
    state = state.copyWith(status: SyncStatus.syncing, message: null);
    try {
      await _service.push(uid, _now);
      state =
          SyncState(status: SyncStatus.synced, lastSyncedAt: DateTime.now());
    } catch (_) {
      state = state.copyWith(
        status: SyncStatus.error,
        message: 'Sync failed — your progress is safe on this device.',
      );
    }
  }

  void _refreshLocalControllers() {
    _ref.invalidate(profilesControllerProvider);
    _ref.invalidate(progressControllerProvider);
    _ref.invalidate(achievementsControllerProvider);
    _ref.invalidate(adaptiveControllerProvider);
    _ref.invalidate(dailyRewardControllerProvider);
    _ref.invalidate(luckySpinControllerProvider);
    _ref.invalidate(settingsControllerProvider);
  }
}

final syncControllerProvider =
    StateNotifierProvider<SyncController, SyncState>((ref) {
  return SyncController(ref);
});
