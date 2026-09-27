part of 'library_bloc.dart';

enum LibraryFilter {
  all,
  wantToRead,
  reading,
  paused,
  abandoned,
  read;

  ReadingStatus? get status => switch (this) {
        LibraryFilter.all => null,
        LibraryFilter.wantToRead => ReadingStatus.wantToRead,
        LibraryFilter.reading => ReadingStatus.reading,
        LibraryFilter.paused => ReadingStatus.paused,
        LibraryFilter.abandoned => ReadingStatus.abandoned,
        LibraryFilter.read => ReadingStatus.read,
      };
}

/// [shelf]: three covers per row on shelves; [swipe]: one large cover at a
/// time.
enum LibraryViewMode { shelf, swipe }

class LibraryState extends Equatable {
  const LibraryState({
    this.status = RequestStatus.initial,
    this.books = const [],
    this.filter = LibraryFilter.all,
    this.shelfFilter,
    this.moodFilter,
    this.paceFilter,
    this.onLoanOnly = false,
    this.viewMode = LibraryViewMode.shelf,
    this.refreshing = false,
    this.offline = false,
    this.pendingChanges = 0,
    this.addingIds = const {},
    this.failure,
    this.actionFailure,
  });

  final RequestStatus status;
  final List<UserBook> books;
  final LibraryFilter filter;

  /// Custom shelf the list is narrowed to, or null for every book.
  final String? shelfFilter;

  /// Mood and pace the list is narrowed to, or null for any.
  final BookMood? moodFilter;
  final ReadingPace? paceFilter;

  /// Only books lent out or borrowed.
  final bool onLoanOnly;
  final LibraryViewMode viewMode;
  final bool refreshing;

  /// The server is unreachable: the list is the copy saved on the device.
  final bool offline;

  /// Edits made offline that are still waiting to be sent.
  final int pendingChanges;

  /// External ids currently being added.
  final Set<String> addingIds;

  /// Failure of the initial load (drives the full-screen error view).
  final Failure? failure;

  /// Failure of the last add/refresh (drives a snackbar). Reset when the next
  /// action starts.
  final Failure? actionFailure;

  List<UserBook> get visibleBooks {
    final wanted = filter.status;
    final shelf = shelfFilter;
    final mood = moodFilter;
    final pace = paceFilter;
    if (!hasActiveFilter) return books;
    return books
        .where((b) => wanted == null || b.status == wanted)
        .where(
          (b) =>
              shelf == null || b.shelves.any((s) => ShelfNames.same(s, shelf)),
        )
        .where((b) => mood == null || b.moods.contains(mood))
        .where((b) => pace == null || b.pace == pace)
        .where((b) => !onLoanOnly || b.loan != null)
        .toList();
  }

  /// Every custom shelf in use with its number of books, by name.
  Map<String, int> get shelfCounts {
    final counts = <String, int>{};
    final spelling = <String, String>{};
    for (final book in books) {
      for (final shelf in book.shelves) {
        final key = shelf.toLowerCase();
        final name = spelling.putIfAbsent(key, () => shelf);
        counts[name] = (counts[name] ?? 0) + 1;
      }
    }
    final names = counts.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return {for (final name in names) name: counts[name]!};
  }

  bool get hasActiveFilter =>
      filter != LibraryFilter.all ||
      shelfFilter != null ||
      moodFilter != null ||
      paceFilter != null ||
      onLoanOnly;

  /// Whether any book is on loan, so the filter is worth offering.
  bool get hasLoans => books.any((b) => b.loan != null);

  bool containsExternalId(String externalId) =>
      books.any((b) => b.book.externalId == externalId);

  LibraryState copyWith({
    RequestStatus? status,
    List<UserBook>? books,
    LibraryFilter? filter,
    ValueGetter<String?>? shelfFilter,
    ValueGetter<BookMood?>? moodFilter,
    ValueGetter<ReadingPace?>? paceFilter,
    bool? onLoanOnly,
    LibraryViewMode? viewMode,
    bool? refreshing,
    bool? offline,
    int? pendingChanges,
    Set<String>? addingIds,
    Failure? Function()? failure,
    Failure? Function()? actionFailure,
  }) {
    return LibraryState(
      status: status ?? this.status,
      books: books ?? this.books,
      filter: filter ?? this.filter,
      shelfFilter: shelfFilter != null ? shelfFilter() : this.shelfFilter,
      moodFilter: moodFilter != null ? moodFilter() : this.moodFilter,
      paceFilter: paceFilter != null ? paceFilter() : this.paceFilter,
      onLoanOnly: onLoanOnly ?? this.onLoanOnly,
      viewMode: viewMode ?? this.viewMode,
      refreshing: refreshing ?? this.refreshing,
      offline: offline ?? this.offline,
      pendingChanges: pendingChanges ?? this.pendingChanges,
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
        shelfFilter,
        moodFilter,
        paceFilter,
        onLoanOnly,
        viewMode,
        refreshing,
        offline,
        pendingChanges,
        addingIds,
        failure,
        actionFailure,
      ];
}
