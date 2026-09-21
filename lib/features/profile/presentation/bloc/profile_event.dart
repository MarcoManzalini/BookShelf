part of 'profile_bloc.dart';

sealed class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

final class ProfileStarted extends ProfileEvent {
  const ProfileStarted();
}

/// Reloads the profile without showing a loading state (e.g. after the goal
/// was changed on the statistics page).
final class ProfileRefreshRequested extends ProfileEvent {
  const ProfileRefreshRequested();
}

final class ProfileDisplayNameSubmitted extends ProfileEvent {
  const ProfileDisplayNameSubmitted(this.displayName);

  final String displayName;

  @override
  List<Object?> get props => [displayName];
}

final class ProfileAvatarSelected extends ProfileEvent {
  const ProfileAvatarSelected({required this.bytes, required this.extension});

  final Uint8List bytes;
  final String extension;

  @override
  List<Object?> get props => [bytes, extension];
}

final class ProfileDeleteAccountRequested extends ProfileEvent {
  const ProfileDeleteAccountRequested();
}
