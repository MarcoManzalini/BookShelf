part of 'library_bloc.dart';

enum LibraryFilter {
  all,
  wantToRead,
  reading,
  read;

  ReadingStatus? get status => switch (this) {
        LibraryFilter.all => null,
        LibraryFilter.wantToRead => ReadingStatus.wantToRead,
        LibraryFilter.reading => ReadingStatus.reading,
        LibraryFilter.read => ReadingStatus.read,
      };
}

enum LibraryViewMode { list, grid }

class LibraryState extends Equatable {
  const LibraryState({
    this.status = RequestStatus.initial,
    this.books = const [],
    this.filter = LibraryFilter.all,
    this.viewMode = LibraryViewMode.list,
    this.refreshing = false,
    this.addingIds = const {},
    this.failure,
    this.actionFailure,
  });

  final RequestStatus status;
  final List<UserBook> books;
  final LibraryFilter filter;
  final LibraryViewMode viewMode;
  final bool refreshing;

  /// External ids currently being added.
  final Set<String> addingIds;

  /// Failure of the initial load (drives the full-screen error view).
  final Failure? failure;

  /// Failure of the last add/refresh (drives a snackbar). Reset when the next
  /// action starts.
  final Failure? actionFailure;

  List<UserBook> get visibleBooks {
    final wanted = filter.status;
    if (wanted == null) return books;
    return books.where((b) => b.status == wanted).toList();
  }

  bool containsExternalId(String externalId) =>
      books.any((b) => b.book.externalId == externalId);

  LibraryState copyWith({
    RequestStatus? status,
    List<UserBook>? books,
    LibraryFilter? filter,
    LibraryViewMode? viewMode,
    bool? refreshing,
    Set<String>? addingIds,
    Failure? Function()? failure,
    Failure? Function()? actionFailure,
  }) {
    return LibraryState(
      status: status ?? this.status,
      books: books ?? this.books,
      filter: filter ?? this.filter,
      viewMode: viewMode ?? this.viewMode,
      refreshing: refreshing ?? this.refreshing,
      addingIds: addingIds ?? this.addingIds,
      failure: failure != null ? failure() : this.failure,
      actionFailure:
          actionFailure != null ? actionFailure() : this.actionFailure,
    );
  }

  @override
  List<Object?> get props => [
        status,
        books,
        filter,
        viewMode,
        refreshing,
        addingIds,
        failure,
        actionFailure,
      ];
}
