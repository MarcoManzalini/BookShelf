import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/request_status.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc(this._repository) : super(const ProfileState()) {
    on<ProfileStarted>(_onStarted);
    on<ProfileDisplayNameSubmitted>(
      _onNameSubmitted,
      transformer: sequential(),
    );
    on<ProfileAvatarSelected>(_onAvatarSelected, transformer: sequential());
    on<ProfileDeleteAccountRequested>(
      _onDeleteRequested,
      transformer: droppable(),
    );
  }

  final ProfileRepository _repository;

  Future<void> _onStarted(
    ProfileStarted event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: RequestStatus.loading, failure: () => null));
    try {
      final profile = await _repository.getProfile();
      emit(state.copyWith(status: RequestStatus.success, profile: profile));
    } on Failure catch (failure) {
      emit(
        state.copyWith(
          status: RequestStatus.failure,
          failure: () => failure,
        ),
      );
    }
  }

  Future<void> _onNameSubmitted(
    ProfileDisplayNameSubmitted event,
    Emitter<ProfileState> emit,
  ) {
    return _mutate(
      emit,
      ProfileAction.updateName,
      () async => state.copyWith(
        profile: await _repository.updateDisplayName(event.displayName.trim()),
      ),
    );
  }

  Future<void> _onAvatarSelected(
    ProfileAvatarSelected event,
    Emitter<ProfileState> emit,
  ) {
    return _mutate(
      emit,
      ProfileAction.updateAvatar,
      () async => state.copyWith(
        profile: await _repository.uploadAvatar(event.bytes, event.extension),
      ),
    );
  }

  Future<void> _onDeleteRequested(
    ProfileDeleteAccountRequested event,
    Emitter<ProfileState> emit,
  ) {
    return _mutate(emit, ProfileAction.deleteAccount, () async {
      await _repository.deleteAccount();
      return state;
    });
  }

  Future<void> _mutate(
    Emitter<ProfileState> emit,
    ProfileAction action,
    Future<ProfileState> Function() run,
  ) async {
    emit(
      state.copyWith(
        action: action,
        actionStatus: RequestStatus.loading,
        failure: () => null,
      ),
    );
    try {
      final next = await run();
      emit(next.copyWith(action: action, actionStatus: RequestStatus.success));
    } on Failure catch (failure) {
      emit(
        state.copyWith(
          action: action,
          actionStatus: RequestStatus.failure,
          failure: () => failure,
        ),
      );
    }
  }
}
