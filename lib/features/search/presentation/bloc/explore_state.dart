part of 'explore_bloc.dart';

class ExploreShelf extends Equatable {
  const ExploreShelf({
    this.status = RequestStatus.initial,
    this.books = const [],
    this.failure,
  });

  final RequestStatus status;
  final List<Book> books;
  final Failure? failure;

  @override
  List<Object?> get props => [status, books, failure];
}

class ExploreState extends Equatable {
  const ExploreState({this.shelves = const {}, this.refreshing = false});

  final Map<ExploreSection, ExploreShelf> shelves;

  /// True from the start of a load until every shelf has answered.
  final bool refreshing;

  ExploreShelf of(ExploreSection section) =>
      shelves[section] ?? const ExploreShelf();

  ExploreState copyWithSections(
    Map<ExploreSection, ExploreShelf> changes, {
    bool? refreshing,
  }) =>
      ExploreState(
        shelves: {...shelves, ...changes},
        refreshing: refreshing ?? this.refreshing,
      );

  @override
  List<Object?> get props => [shelves, refreshing];
}
