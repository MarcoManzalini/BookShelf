import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/auth_snapshot.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repository)
      : super(AuthState.fromSnapshot(_repository.current)) {
    on<AuthStarted>(_onStarted);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  final AuthRepository _repository;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) {
    return emit.forEach<AuthSnapshot>(
      _repository.changes,
      onData: AuthState.fromSnapshot,
    );
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _repository.signOut();
    } on Failure catch (failure) {
      emit(
        AuthState(
          status: state.status,
          user: state.user,
          failure: failure,
        ),
      );
    }
  }
}
