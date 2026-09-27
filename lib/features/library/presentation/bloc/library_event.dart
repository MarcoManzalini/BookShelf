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

/// Narrows the list to one custom shelf; null shows every shelf.
final class LibraryShelfFilterChanged extends LibraryEvent {
  const LibraryShelfFilterChanged(this.shelf);

  final String? shelf;

  @override
  List<Object?> get props => [shelf];
}

/// Narrows the list to one mood; null shows every book.
final class LibraryMoodFilterChanged extends LibraryEvent {
  const LibraryMoodFilterChanged(this.mood);

  final BookMood? mood;

  @override
  List<Object?> get props => [mood];
}

final class LibraryPaceFilterChanged extends LibraryEvent {
  const LibraryPaceFilterChanged(this.pace);

  final ReadingPace? pace;

  @override
  List<Object?> get props => [pace];
}

/// Shows only the books lent out or borrowed.
final class LibraryLoanFilterChanged extends LibraryEvent {
  const LibraryLoanFilterChanged(this.onLoanOnly);

  final bool onLoanOnly;

  @override
  List<Object?> get props => [onLoanOnly];
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

/// The repository's connection state or unsent-edit count changed.
final class LibrarySyncChanged extends LibraryEvent {
  const LibrarySyncChanged(this.sync);

  final SyncStatus sync;

  @override
  List<Object?> get props => [sync];
}

/// Resets state on logout.
final class LibraryCleared extends LibraryEvent {
  const LibraryCleared();
}
