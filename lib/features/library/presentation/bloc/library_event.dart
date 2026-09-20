part of 'library_bloc.dart';

sealed class LibraryEvent extends Equatable {
  const LibraryEvent();

  @override
  List<Object?> get props => [];
}

/// Loads the library and subscribes to repository changes.
final class LibraryStarted extends LibraryEvent {
  const LibraryStarted();
}

final class LibraryRefreshRequested extends LibraryEvent {
  const LibraryRefreshRequested();
}

final class LibraryFilterChanged extends LibraryEvent {
  const LibraryFilterChanged(this.filter);

  final LibraryFilter filter;

  @override
  List<Object?> get props => [filter];
}

final class LibraryViewModeToggled extends LibraryEvent {
  const LibraryViewModeToggled();
}

final class LibraryBookAdded extends LibraryEvent {
  const LibraryBookAdded(this.book, this.status);

  final Book book;
  final ReadingStatus status;

  @override
  List<Object?> get props => [book, status];
}

/// Resets state on logout.
final class LibraryCleared extends LibraryEvent {
  const LibraryCleared();
}
