import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/app_config.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._client);

  final SupabaseClient _client;

  GoTrueClient get _auth => _client.auth;

  Session? get currentSession => _auth.currentSession;

  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  Future<void> signIn(String email, String password) =>
      _auth.signInWithPassword(email: email, password: password);

  Future<AuthResponse> signUp(
    String email,
    String password,
    String? displayName,
  ) {
    return _auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: AppConfig.authRedirectUrl,
      data: displayName == null ? null : {'display_name': displayName},
    );
  }

  Future<void> sendPasswordReset(String email) => _auth.resetPasswordForEmail(
        email,
        redirectTo: AppConfig.authRedirectUrl,
      );

  Future<void> updatePassword(String password) =>
      _auth.updateUser(UserAttributes(password: password));

  /// Opens the provider's consent page in the system browser; the session
  /// arrives later through the `login-callback` deep link.
  Future<bool> signInWithOAuth(OAuthProvider provider) => _auth.signInWithOAuth(
        provider,
        redirectTo: AppConfig.authRedirectUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

  Future<void> signOut() => _auth.signOut();
}
