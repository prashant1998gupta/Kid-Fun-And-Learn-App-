import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/services/firebase_service.dart';
import '../domain/parent_account.dart';

/// A user-facing auth failure. Messages are safe to show verbatim in the UI.
class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Wraps Firebase Auth + the social providers behind a small, typed surface.
/// Every method fails fast and friendly when Firebase isn't configured, so the
/// app stays usable in pure-offline mode.
class AuthService {
  AuthService(this._firebase);
  final FirebaseService _firebase;

  fb.FirebaseAuth get _auth => fb.FirebaseAuth.instance;

  void _ensureAvailable() {
    if (!_firebase.isAvailable) {
      throw const AuthException(
        'Cloud accounts aren\'t set up yet — you can keep playing offline.',
      );
    }
  }

  /// Emits the current parent (or null when signed out). Emits a single null
  /// immediately when Firebase is offline so listeners settle deterministically.
  Stream<ParentAccount?> authStateChanges() {
    if (!_firebase.isAvailable) return Stream.value(null);
    return _auth.authStateChanges().map(_toAccount);
  }

  ParentAccount? get current =>
      _firebase.isAvailable ? _toAccount(_auth.currentUser) : null;

  ParentAccount? _toAccount(fb.User? u) {
    if (u == null) return null;
    return ParentAccount(
      uid: u.uid,
      provider: _providerFrom(u),
      email: u.email,
      displayName: u.displayName,
      phoneNumber: u.phoneNumber,
    );
  }

  AuthProvider _providerFrom(fb.User u) {
    final ids = u.providerData.map((p) => p.providerId).toList();
    if (ids.contains('google.com')) return AuthProvider.google;
    if (ids.contains('apple.com')) return AuthProvider.apple;
    if (ids.contains('phone')) return AuthProvider.phone;
    return AuthProvider.email;
  }

  // ---- Google -------------------------------------------------------------
  Future<ParentAccount> signInWithGoogle() async {
    _ensureAvailable();
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw const AuthException('Sign-in cancelled.');
      }
      final auth = await googleUser.authentication;
      final cred = fb.GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );
      final result = await _auth.signInWithCredential(cred);
      return _requireAccount(result.user);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_friendly(e));
    }
  }

  // ---- Apple --------------------------------------------------------------
  Future<ParentAccount> signInWithApple() async {
    _ensureAvailable();
    try {
      final apple = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final cred = fb.OAuthProvider('apple.com').credential(
        idToken: apple.identityToken,
        accessToken: apple.authorizationCode,
      );
      final result = await _auth.signInWithCredential(cred);
      // Apple only returns the name on first consent — persist it if present.
      final name = [apple.givenName, apple.familyName]
          .whereType<String>()
          .join(' ')
          .trim();
      if (name.isNotEmpty && result.user?.displayName == null) {
        await result.user?.updateDisplayName(name);
      }
      return _requireAccount(result.user);
    } on SignInWithAppleAuthorizationException {
      throw const AuthException('Sign-in cancelled.');
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_friendly(e));
    }
  }

  // ---- Email / password ---------------------------------------------------
  Future<ParentAccount> signInWithEmail(String email, String password) async {
    _ensureAvailable();
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _requireAccount(result.user);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_friendly(e));
    }
  }

  Future<ParentAccount> registerWithEmail(String email, String password) async {
    _ensureAvailable();
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _requireAccount(result.user);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_friendly(e));
    }
  }

  Future<void> sendPasswordReset(String email) async {
    _ensureAvailable();
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_friendly(e));
    }
  }

  // ---- Phone (SMS OTP) ----------------------------------------------------
  /// Starts phone verification. On Android auto-retrieval the [onAutoVerified]
  /// callback fires with a resolved account; otherwise [onCodeSent] delivers a
  /// verificationId to pair with the user-entered SMS code in [confirmSmsCode].
  Future<void> startPhoneSignIn(
    String phoneNumber, {
    required void Function(String verificationId) onCodeSent,
    required void Function(ParentAccount account) onAutoVerified,
    required void Function(AuthException error) onError,
  }) async {
    _ensureAvailable();
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber.trim(),
      verificationCompleted: (cred) async {
        try {
          final result = await _auth.signInWithCredential(cred);
          onAutoVerified(_requireAccount(result.user));
        } on fb.FirebaseAuthException catch (e) {
          onError(AuthException(_friendly(e)));
        }
      },
      verificationFailed: (e) => onError(AuthException(_friendly(e))),
      codeSent: (verificationId, _) => onCodeSent(verificationId),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<ParentAccount> confirmSmsCode(
    String verificationId,
    String smsCode,
  ) async {
    _ensureAvailable();
    try {
      final cred = fb.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );
      final result = await _auth.signInWithCredential(cred);
      return _requireAccount(result.user);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_friendly(e));
    }
  }

  // ---- Session ------------------------------------------------------------
  Future<void> signOut() async {
    if (!_firebase.isAvailable) return;
    // Google sign-out is best-effort; ignore its failure (return null to
    // satisfy catchError's GoogleSignInAccount? return type).
    await GoogleSignIn().signOut().catchError((_) => null);
    await _auth.signOut();
  }

  ParentAccount _requireAccount(fb.User? user) {
    final account = _toAccount(user);
    if (account == null) {
      throw const AuthException('Sign-in failed — please try again.');
    }
    return account;
  }

  String _friendly(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address doesn\'t look right.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'Please choose a stronger password (6+ characters).';
      case 'invalid-verification-code':
        return 'That code isn\'t correct — check and try again.';
      case 'network-request-failed':
        return 'No connection — check your network and retry.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and retry.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(FirebaseService.instance);
});
