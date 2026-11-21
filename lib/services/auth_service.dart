import 'package:supabase_flutter/supabase_flutter.dart';

/// Result of creating an account.
enum SignUpOutcome {
  /// The account exists and the user is already logged in.
  signedIn,

  /// The project asks to confirm the email first: no session yet.
  needsEmailConfirmation,

  /// The email already has an account: no email is sent, the user should
  /// log in instead.
  alreadyRegistered,
}

/// Authentication contract. Screens depend on this, not on Supabase, so
/// widget tests can use a fake that never touches the network.
abstract class AuthService {
  bool get isSignedIn;

  String? get currentEmail;

  /// Emits `true` / `false` every time the user logs in or out (also when
  /// a saved session is restored at startup).
  Stream<bool> get signedInChanges;

  Future<void> signIn({required String email, required String password});

  Future<SignUpOutcome> signUp({required String email, required String password});

  Future<void> signOut();
}

/// Real implementation with Supabase Auth. supabase_flutter stores the
/// session on the device, so the user stays logged in after restarting.
class SupabaseAuthService implements AuthService {
  SupabaseAuthService(this._auth);

  final GoTrueClient _auth;

  @override
  bool get isSignedIn => _auth.currentSession != null;

  @override
  String? get currentEmail => _auth.currentUser?.email;

  @override
  Stream<bool> get signedInChanges => _auth.onAuthStateChange.map((state) => state.session != null);

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithPassword(email: email.trim(), password: password);
  }

  @override
  Future<SignUpOutcome> signUp({required String email, required String password}) async {
    final response = await _auth.signUp(email: email.trim(), password: password);
    if (response.session != null) return SignUpOutcome.signedIn;
    // To avoid revealing which emails are registered, Supabase answers a
    // repeated sign-up "successfully" but with a user that has no
    // identities, and sends no email. We detect that case to guide the user.
    if (response.user?.identities?.isEmpty ?? false) return SignUpOutcome.alreadyRegistered;
    return SignUpOutcome.needsEmailConfirmation;
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
