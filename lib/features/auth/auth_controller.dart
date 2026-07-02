import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/firebase_service.dart';
import '../../core/services/messaging_service.dart';
import '../sync/sync_controller.dart';
import 'data/auth_service.dart';
import 'domain/parent_account.dart';

enum AuthStatus { unknown, signedOut, signedIn }

class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.account,
    this.busy = false,
    this.error,
  });

  final AuthStatus status;
  final ParentAccount? account;

  /// A sign-in action is in flight (used to disable buttons + show spinners).
  final bool busy;
  final String? error;

  /// Whether cloud accounts are even available on this build.
  bool get cloudEnabled => FirebaseService.instance.isAvailable;

  AuthState copyWith({
    AuthStatus? status,
    ParentAccount? account,
    bool clearAccount = false,
    bool? busy,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      account: clearAccount ? null : (account ?? this.account),
      busy: busy ?? this.busy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Owns the parent's session. Subscribes to auth changes, exposes the sign-in
/// actions, and fans out session events to sync + messaging.
class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref) : super(const AuthState()) {
    _sub = _service.authStateChanges().listen(_onAccountChanged);
  }

  final Ref _ref;
  late final StreamSubscription<ParentAccount?> _sub;

  AuthService get _service => _ref.read(authServiceProvider);

  void _onAccountChanged(ParentAccount? account) {
    state = state.copyWith(
      status: account == null ? AuthStatus.signedOut : AuthStatus.signedIn,
      account: account,
      clearAccount: account == null,
      busy: false,
    );
    // Kick cloud side-effects; both no-op safely when offline.
    _ref.read(syncControllerProvider.notifier).onAccountChanged(account);
    if (account != null) {
      MessagingService.instance.onSignedIn(account.uid);
    }
  }

  /// Runs a sign-in action with shared busy/error handling.
  Future<bool> _run(Future<ParentAccount> Function() action) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      await action();
      // The authStateChanges stream flips status → signedIn.
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(busy: false, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        busy: false,
        error: 'Something went wrong. Please try again.',
      );
      return false;
    }
  }

  Future<bool> signInWithGoogle() => _run(_service.signInWithGoogle);
  Future<bool> signInWithApple() => _run(_service.signInWithApple);

  Future<bool> signInWithEmail(String email, String password) =>
      _run(() => _service.signInWithEmail(email, password));

  Future<bool> registerWithEmail(String email, String password) =>
      _run(() => _service.registerWithEmail(email, password));

  Future<void> sendPasswordReset(String email) async {
    try {
      await _service.sendPasswordReset(email);
    } on AuthException catch (e) {
      state = state.copyWith(error: e.message);
    }
  }

  Future<bool> confirmSmsCode(String verificationId, String smsCode) =>
      _run(() => _service.confirmSmsCode(verificationId, smsCode));

  Future<void> signOut() async {
    await _service.signOut();
    // authStateChanges flips to signedOut; if offline, force it locally.
    if (!state.cloudEnabled) {
      state = state.copyWith(status: AuthStatus.signedOut, clearAccount: true);
    }
  }

  void clearError() => state = state.copyWith(clearError: true);

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref);
});
