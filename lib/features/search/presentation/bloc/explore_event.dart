part of 'explore_bloc.dart';

sealed class ExploreEvent extends Equatable {
  const ExploreEvent();

  @override
  List<Object?> get props => [];
}

final class ExploreStarted extends ExploreEvent {
  const ExploreStarted();
}

/// Pull-to-refresh: bypasses the repository cache.
final class ExploreRefreshRequested extends ExploreEvent {
  const ExploreRefreshRequested();
}
