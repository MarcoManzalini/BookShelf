import 'package:equatable/equatable.dart';

import 'app_user.dart';

enum AuthStatus { authenticated, unauthenticated, passwordRecovery }

class AuthSnapshot extends Equatable {
  const AuthSnapshot(this.status, [this.user]);

  const AuthSnapshot.unauthenticated()
      : status = AuthStatus.unauthenticated,
        user = null;

  final AuthStatus status;
  final AppUser? user;

  @override
  List<Object?> get props => [status, user];
}
