import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../core/errors/error_mapper.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/auth_snapshot.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  @override
  AuthSnapshot get current => _fromSession(_remote.currentSession);

  @override
  Stream<AuthSnapshot> get changes => _remote.authStateChanges.map(
        (state) => state.event == supabase.AuthChangeEvent.passwordRecovery
            ? AuthSnapshot(AuthStatus.passwordRecovery, _user(state.session))
            : _fromSession(state.session),
      );

  @override
  Future<void> signIn({required String email, required String password}) {
    return _guard(() => _remote.signIn(email, password));
  }

  @override
  Future<SignUpResult> signUp({
    required String email,
    required String password,
    String? displayName,
  }) {
    return _guard(() async {
      final response = await _remote.signUp(email, password, displayName);
      return response.session != null
          ? SignUpResult.signedIn
          : SignUpResult.confirmationRequired;
    });
  }

  @override
  Future<void> sendPasswordReset(String email) {
    return _guard(() => _remote.sendPasswordReset(email));
  }

  @override
  Future<void> updatePassword(String newPassword) {
    return _guard(() => _remote.updatePassword(newPassword));
  }

  @override
  Future<void> signInWithProvider(SocialProvider provider) {
    return _guard(
      () => _remote.signInWithOAuth(
        switch (provider) {
          SocialProvider.google => supabase.OAuthProvider.google,
          SocialProvider.apple => supabase.OAuthProvider.apple,
        },
      ),
    );
  }

  @override
  Future<void> signOut() => _guard(_remote.signOut);

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      throw mapError(e);
    }
  }

  static AuthSnapshot _fromSession(supabase.Session? session) {
    final user = _user(session);
    return user == null
        ? const AuthSnapshot.unauthenticated()
        : AuthSnapshot(AuthStatus.authenticated, user);
  }

  static AppUser? _user(supabase.Session? session) {
    final user = session?.user;
    if (user == null) return null;
    return AppUser(id: user.id, email: user.email ?? '');
  }
}
