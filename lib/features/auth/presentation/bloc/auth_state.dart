part of 'auth_bloc.dart';

class AuthState extends Equatable {
  const AuthState({required this.status, this.user, this.failure});

  factory AuthState.fromSnapshot(AuthSnapshot snapshot) =>
      AuthState(status: snapshot.status, user: snapshot.user);

  final AuthStatus status;
  final AppUser? user;

  /// Set when an explicit action (logout) failed.
  final Failure? failure;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  @override
  List<Object?> get props => [status, user, failure];
}
