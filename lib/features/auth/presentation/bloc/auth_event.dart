part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Starts listening to Supabase `onAuthStateChange`.
final class AuthStarted extends AuthEvent {
  const AuthStarted();
}

final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
