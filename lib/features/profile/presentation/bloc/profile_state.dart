part of 'profile_bloc.dart';

enum ProfileAction { none, updateName, updateAvatar, deleteAccount }

class ProfileState extends Equatable {
  const ProfileState({
    this.status = RequestStatus.initial,
    this.profile,
    this.action = ProfileAction.none,
    this.actionStatus = RequestStatus.initial,
    this.failure,
  });

  /// Status of the initial profile load.
  final RequestStatus status;
  final Profile? profile;

  /// Last mutation and its status, for snackbars via BlocListener.
  final ProfileAction action;
  final RequestStatus actionStatus;
  final Failure? failure;

  ProfileState copyWith({
    RequestStatus? status,
    Profile? profile,
    ProfileAction? action,
    RequestStatus? actionStatus,
    Failure? Function()? failure,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      action: action ?? this.action,
      actionStatus: actionStatus ?? this.actionStatus,
      failure: failure != null ? failure() : this.failure,
    );
  }

  @override
  List<Object?> get props => [status, profile, action, actionStatus, failure];
}
