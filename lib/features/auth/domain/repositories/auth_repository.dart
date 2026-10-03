import '../entities/auth_snapshot.dart';

enum SignUpResult { signedIn, confirmationRequired }

enum SocialProvider { apple }

abstract interface class AuthRepository {
  AuthSnapshot get current;

  /// Emits on every Supabase `onAuthStateChange` event.
  Stream<AuthSnapshot> get changes;

  /// All methods below throw [Failure] on error.
  Future<void> signIn({required String email, required String password});

  Future<SignUpResult> signUp({
    required String email,
    required String password,
    String? displayName,
  });

  Future<void> sendPasswordReset(String email);

  Future<void> updatePassword(String newPassword);

  Future<void> signInWithProvider(SocialProvider provider);

  Future<void> signOut();
}
