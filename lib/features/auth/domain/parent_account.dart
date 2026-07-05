import 'package:equatable/equatable.dart';

/// How a parent authenticated. Children never authenticate (COPPA) — all child
/// data lives under the parent's owned subtree.
enum AuthProvider {
  google('google', 'Google'),
  apple('apple', 'Apple'),
  email('email', 'Email'),
  phone('phone', 'Phone');

  const AuthProvider(this.id, this.label);
  final String id;
  final String label;

  static AuthProvider fromId(String? id) => AuthProvider.values.firstWhere(
        (p) => p.id == id,
        orElse: () => AuthProvider.email,
      );
}

/// The signed-in parent. This is the only human with credentials in KidVerse;
/// it owns the `parents/{uid}` document tree in Firestore.
class ParentAccount extends Equatable {
  const ParentAccount({
    required this.uid,
    required this.provider,
    this.email,
    this.displayName,
    this.phoneNumber,
  });

  final String uid;
  final AuthProvider provider;
  final String? email;
  final String? displayName;
  final String? phoneNumber;

  /// A friendly label for the account chip in the parent dashboard.
  String get label => displayName?.trim().isNotEmpty == true
      ? displayName!
      : email ?? phoneNumber ?? 'Parent';

  @override
  List<Object?> get props => [uid, provider, email, displayName, phoneNumber];
}
