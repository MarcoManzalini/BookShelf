import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/request_status.dart';
import '../../domain/repositories/auth_repository.dart';

enum AuthFormResult {
  none,
  signedIn,
  confirmationEmailSent,
  resetEmailSent,
  passwordUpdated,
}

class AuthFormState extends Equatable {
  const AuthFormState({
    this.status = RequestStatus.initial,
    this.result = AuthFormResult.none,
    this.failure,
  });

  final RequestStatus status;
  final AuthFormResult result;
  final Failure? failure;

  @override
  List<Object?> get props => [status, result, failure];
}

/// Drives the login / register / forgot / reset password forms.
class AuthFormCubit extends Cubit<AuthFormState> {
  AuthFormCubit(this._repository) : super(const AuthFormState());

  final AuthRepository _repository;

  Future<void> signIn(String email, String password) {
    return _run(() async {
      await _repository.signIn(email: email.trim(), password: password);
      return AuthFormResult.signedIn;
    });
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) {
    return _run(() async {
      final result = await _repository.signUp(
        email: email.trim(),
        password: password,
        displayName: displayName.trim().isEmpty ? null : displayName.trim(),
      );
      return result == SignUpResult.signedIn
          ? AuthFormResult.signedIn
          : AuthFormResult.confirmationEmailSent;
    });
  }

  Future<void> sendPasswordReset(String email) {
    return _run(() async {
      await _repository.sendPasswordReset(email.trim());
      return AuthFormResult.resetEmailSent;
    });
  }

  Future<void> updatePassword(String password) {
    return _run(() async {
      await _repository.updatePassword(password);
      return AuthFormResult.passwordUpdated;
    });
  }

  Future<void> signInWithProvider(SocialProvider provider) {
    return _run(() async {
      await _repository.signInWithProvider(provider);
      return AuthFormResult.signedIn;
    });
  }

  Future<void> _run(Future<AuthFormResult> Function() action) async {
    if (state.status.isLoading) return;
    emit(const AuthFormState(status: RequestStatus.loading));
    try {
      final result = await action();
      emit(AuthFormState(status: RequestStatus.success, result: result));
    } on Failure catch (failure) {
      emit(AuthFormState(status: RequestStatus.failure, failure: failure));
    }
  }
}
