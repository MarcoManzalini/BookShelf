import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/request_status.dart';
import '../../../library/domain/entities/book_format.dart';
import '../../../library/domain/entities/book_loan.dart';
import '../../../library/domain/entities/book_read.dart';
import '../../../library/domain/entities/book_series.dart';
import '../../../library/domain/entities/book_vibe.dart';
import '../../../library/domain/entities/reading_status.dart';
import '../../../library/domain/entities/shelf_names.dart';
import '../../../library/domain/entities/user_book.dart';
import '../../../library/domain/repositories/library_repository.dart';
import '../../../library/domain/usecases/add_book_to_library.dart';
import '../../../search/domain/entities/author_info.dart';
import '../../../quotes/domain/entities/book_quote.dart';
import '../../../quotes/domain/repositories/quote_repository.dart';
import '../../../stats/domain/entities/reading_log.dart';
import '../../../stats/domain/repositories/reading_log_repository.dart';
import '../../../search/domain/entities/book.dart';
import '../../../search/domain/entities/book_edition.dart';
import '../../../search/domain/entities/reader_activity.dart';
import '../../../search/domain/repositories/book_search_repository.dart';

part 'book_details_event.dart';
part 'book_details_state.dart';

class BookDetailsBloc extends Bloc<BookDetailsEvent, BookDetailsState> {
  BookDetailsBloc({
    required LibraryRepository libraryRepository,
    required BookSearchRepository searchRepository,
    required AddBookToLibrary addBook,
    required ReadingLogRepository readingLogs,
    required QuoteRepository quotes,
  })  : _library = libraryRepository,
        _search = searchRepository,
        _addBook = addBook,
        _logs = readingLogs,
        _quotes = quotes,
        super(const BookDetailsState()) {
    on<BookDetailsLibraryRequested>(_onLibraryRequested);
    on<BookDetailsPreviewRequested>(_onPreviewRequested);
    on<BookDetailsExtrasRequested>(_onExtrasRequested);
    on<BookDetailsAddRequested>(_onAddRequested, transformer: droppable());
    on<BookDetailsStatusChanged>(
      (e, emit) => _edit(emit, (b) => b.withStatus(e.status)),
      transformer: sequential(),
    );
    on<BookDetailsProgressChanged>(
      _onProgressChanged,
      transformer: sequential(),
    );
    on<BookDetailsSessionLogged>(_onSessionLogged, transformer: sequential());
    on<BookDetailsLogsRequested>(_onLogsRequested);
    on<BookDetailsRatingChanged>(
      (e, emit) => _edit(emit, (b) => b.copyWith(rating: () => e.rating)),
      transformer: sequential(),
    );
    on<BookDetailsNotesChanged>(
      (e, emit) async {
        final trimmed = e.notes.trim();
        await _edit(
          emit,
          (b) => b.copyWith(notes: () => trimmed.isEmpty ? null : trimmed),
        );
      },
      transformer: sequential(),
    );
    on<BookDetailsEditionSelected>(
      _onEditionSelected,
      transformer: sequential(),
    );
    on<BookDetailsShelvesChanged>(
      (e, emit) =>
          _edit(emit, (b) => b.copyWith(shelves: ShelfNames.clean(e.shelves))),
      transformer: sequential(),
    );
    on<BookDetailsDateChanged>(
      (e, emit) => _edit(emit, (b) {
        return switch (e.field) {
          ReadingDateField.startedAt => b.copyWith(startedAt: () => e.date),
          ReadingDateField.finishedAt => b.copyWith(finishedAt: () => e.date),
        };
      }),
      transformer: sequential(),
    );
    on<BookDetailsRereadStarted>(
      (e, emit) => _edit(emit, (b) => b.withReread()),
      transformer: droppable(),
    );
    on<BookDetailsPastReadAdded>(
      (e, emit) =>
          _edit(emit, (b) => b.copyWith(pastReads: [...b.pastReads, e.read])),
      transformer: sequential(),
    );
    on<BookDetailsPastReadRemoved>(
      (e, emit) => _edit(emit, (b) {
        // Only one copy: two undated reads are equal but both count.
        final reads = [...b.pastReads];
        final index = reads.indexOf(e.read);
        if (index >= 0) reads.removeAt(index);
        return b.copyWith(pastReads: reads);
      }),
      transformer: sequential(),
    );
    on<BookDetailsFormatChanged>(
      (e, emit) => _edit(emit, (b) {
        // The bookmark means pages in one format and minutes in the other:
        // switching between them starts it again rather than mislead.
        final unitChanged =
            (b.format == BookFormat.audio) != (e.format == BookFormat.audio);
        final changed = b.copyWith(format: e.format);
        if (changed.status == ReadingStatus.read) {
          return changed.copyWith(
            currentPage: changed.progressTotal ?? b.currentPage,
          );
        }
        return unitChanged ? changed.copyWith(currentPage: 0) : changed;
      }),
      transformer: sequential(),
    );
    on<BookDetailsDurationChanged>(
      (e, emit) => _edit(emit, (b) {
        final minutes = e.minutes;
        final updated = b.copyWith(
          durationMinutes: () =>
              minutes != null && minutes > 0 ? minutes : null,
        );
        final total = updated.progressTotal;
        return b.isAudio && total != null && updated.currentPage > total
            ? updated.copyWith(currentPage: total)
            : updated;
      }),
      transformer: sequential(),
    );
    on<BookDetailsSeriesChanged>(
      (e, emit) => _edit(emit, (b) => b.copyWith(series: () => e.series)),
      transformer: sequential(),
    );
    on<BookDetailsMoodsChanged>(
      (e, emit) => _edit(
        emit,
        (b) => b.copyWith(
          moods: e.moods.toSet().take(BookMood.maxPerBook).toList(),
        ),
      ),
      transformer: sequential(),
    );
    on<BookDetailsPaceChanged>(
      (e, emit) => _edit(emit, (b) => b.copyWith(pace: () => e.pace)),
      transformer: sequential(),
    );
    on<BookDetailsLoanChanged>(
      (e, emit) => _edit(emit, (b) => b.copyWith(loan: () => e.loan)),
      transformer: sequential(),
    );
    on<BookDetailsQuotesRequested>(_onQuotesRequested);
    on<BookDetailsQuoteSaved>(_onQuoteSaved, transformer: sequential());
    on<BookDetailsQuoteRemoved>(_onQuoteRemoved, transformer: sequential());
    on<BookDetailsRemoveRequested>(_onRemove, transformer: droppable());
  }

  final LibraryRepository _library;
  final BookSearchRepository _search;
  final AddBookToLibrary _addBook;
  final ReadingLogRepository _logs;
  final QuoteRepository _quotes;

  /// Whether the work-level lookup (author ids, rating, ...) already ran, so
  /// the extras step does not repeat it.
  bool _detailsLoaded = false;

  Future<void> _onLibraryRequested(
    BookDetailsLibraryRequested event,
    Emitter<BookDetailsState> emit,
  ) async {
    emit(state.copyWith(status: RequestStatus.loading, failure: () => null));
    try {
      final userBook = await _library.getById(event.userBookId);
      if (userBook == null) {
        emit(
          state.copyWith(
            status: RequestStatus.failure,
            failure: () => const Failure(FailureCode.notFound),
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          status: RequestStatus.success,
          book: userBook.book,
          userBook: () => userBook,
        ),
      );
      add(const BookDetailsExtrasRequested());
      add(const BookDetailsLogsRequested());
      add(const BookDetailsQuotesRequested());
    } on Failure catch (failure) {
      emit(
        state.copyWith(
          status: RequestStatus.failure,
          failure: () => failure,
        ),
      );
    }
  }

  Future<void> _onPreviewRequested(
    BookDetailsPreviewRequested event,
    Emitter<BookDetailsState> emit,
  ) async {
    final saved = _library.findCachedByExternalId(event.book.externalId);
    if (saved != null) {
      emit(
        state.copyWith(
          status: RequestStatus.success,
          book: saved.book,
          userBook: () => saved,
        ),
      );
      add(const BookDetailsExtrasRequested());
      add(const BookDetailsLogsRequested());
      add(const BookDetailsQuotesRequested());
      return;
    }

    emit(state.copyWith(status: RequestStatus.success, book: event.book));
    if (event.book.description == null) {
      // Description and extra images are best effort: the preview is already
      // usable without them.
      _detailsLoaded = true;
      try {
        final detailed = await _search.getBookDetails(event.book);
        if (!state.isInLibrary) emit(state.copyWith(book: detailed));
      } on Failure {
        // Keep the basic preview.
      }
    }
    add(const BookDetailsExtrasRequested());
  }

  /// Author profile and related books. Best effort and independent of each
  /// other: each section simply stays hidden if its lookup fails.
  Future<void> _onExtrasRequested(
    BookDetailsExtrasRequested event,
    Emitter<BookDetailsState> emit,
  ) async {
    final loaded = state.book;
    if (loaded == null) return;

    var current = loaded;
    if (!_detailsLoaded) {
      // Saved books do not store author ids or the community rating.
      _detailsLoaded = true;
      try {
        current = await _search.getBookDetails(current);
        emit(state.copyWith(book: current));
      } on Failure {
        // Related content below may still work from what is stored.
      }
    }

    final book = current;
    final authorKey = book.authorKeys.firstOrNull;
    await Future.wait([
      _load(
        () => _search.getReaderActivity(book),
        (activity) => emit(state.copyWith(activity: activity)),
      ),
      if (authorKey != null) ...[
        _load(
          () => _search.getAuthor(authorKey),
          (author) => emit(state.copyWith(author: author)),
        ),
        _load(
          () => _search.getBooksByAuthor(authorKey, exclude: book.externalId),
          (books) => emit(state.copyWith(moreByAuthor: books)),
        ),
      ],
      if (book.subjects.isNotEmpty)
        _load(
          () => _search.getSimilarBooks(book),
          (books) => emit(state.copyWith(similarBooks: books)),
        ),
    ]);
  }

  Future<void> _load<T>(
    Future<T> Function() request,
    void Function(T value) onLoaded,
  ) async {
    try {
      final value = await request();
      if (value != null) onLoaded(value);
    } on Failure {
      // Section stays hidden.
    }
  }

  /// A saved book stores the edition; a preview only remembers it until the
  /// book is added.
  Future<void> _onEditionSelected(
    BookDetailsEditionSelected event,
    Emitter<BookDetailsState> emit,
  ) async {
    if (state.isInLibrary) {
      await _edit(emit, (b) => b.withEdition(event.edition));
      // Keep what the page already loaded that is not stored (rating, keys).
      final saved = state.userBook;
      final loaded = state.book;
      if (saved != null && loaded != null) {
        emit(
          state.copyWith(
            book: event.edition.applyTo(loaded).copyWith(
                  description: saved.book.description,
                ),
          ),
        );
      }
      return;
    }
    final book = state.book;
    if (book != null) emit(state.copyWith(book: event.edition.applyTo(book)));
  }

  Future<void> _onAddRequested(
    BookDetailsAddRequested event,
    Emitter<BookDetailsState> emit,
  ) async {
    final book = state.book;
    if (book == null || state.isInLibrary) return;
    emit(
      state.copyWith(
        saveStatus: RequestStatus.loading,
        failure: () => null,
      ),
    );
    try {
      final saved = await _addBook(book, event.status);
      emit(
        state.copyWith(
          saveStatus: RequestStatus.success,
          // Author ids, rating and extra images are not stored in the library;
          // keep the ones already loaded for this page.
          book: saved.book.copyWith(
            authorKeys: book.authorKeys,
            ratingAverage: book.ratingAverage,
            ratingsCount: book.ratingsCount,
            extraImages: book.extraImages,
          ),
          userBook: () => saved,
        ),
      );
    } on Failure catch (failure) {
      emit(
        state.copyWith(
          saveStatus: RequestStatus.failure,
          failure: () => failure,
        ),
      );
    }
  }

  Future<void> _onProgressChanged(
    BookDetailsProgressChanged event,
    Emitter<BookDetailsState> emit,
  ) async {
    final before = state.userBook?.currentPage ?? 0;
    final saved = await _edit(emit, (b) => b.withProgress(event.page));
    if (!saved) return;
    final after = state.userBook?.currentPage ?? before;
    // Only forward movement counts as reading (or listening).
    if (after > before) {
      final audio = state.userBook?.isAudio ?? false;
      await _recordLog(
        emit,
        pages: audio ? 0 : after - before,
        minutes: audio ? after - before : null,
        endPage: after,
      );
    }
  }

  /// A finished reading session: moves the bookmark and logs the pages/time.
  Future<void> _onSessionLogged(
    BookDetailsSessionLogged event,
    Emitter<BookDetailsState> emit,
  ) async {
    final before = state.userBook?.currentPage ?? 0;
    final saved = await _edit(emit, (b) => b.withProgress(event.endPage));
    final after = state.userBook?.currentPage ?? before;
    // An unchanged page is fine (time-only session) but a failed save is not.
    if (!saved && after != event.endPage) return;
    final moved = after > before ? after - before : 0;
    // For an audiobook the bookmark is a minute: what moved is time.
    final audio = state.userBook?.isAudio ?? false;
    final pages = audio ? 0 : moved;
    final minutes =
        audio ? (event.minutes ?? (moved > 0 ? moved : null)) : event.minutes;
    if (pages == 0 && minutes == null) return;
    await _recordLog(
      emit,
      pages: pages,
      minutes: minutes,
      endPage: after,
    );
  }

  Future<void> _recordLog(
    Emitter<BookDetailsState> emit, {
    required int pages,
    int? minutes,
    int? endPage,
  }) async {
    final userBook = state.userBook;
    if (userBook == null) return;
    try {
      final log = await _logs.add(
        userBookId: userBook.id,
        pages: pages,
        minutes: minutes,
        endPage: endPage,
      );
      emit(state.copyWith(logs: [log, ...state.logs]));
    } on Failure {
      // The reading itself is saved; the history is best effort.
    }
  }

  Future<void> _onLogsRequested(
    BookDetailsLogsRequested event,
    Emitter<BookDetailsState> emit,
  ) async {
    final userBook = state.userBook;
    if (userBook == null) return;
    try {
      // Read `state` after the await: other loads run concurrently and must
      // not be overwritten with a stale copy.
      final logs = await _logs.forBook(userBook.id);
      emit(state.copyWith(logs: logs));
    } on Failure {
      // No history shown.
    }
  }

  Future<void> _onQuotesRequested(
    BookDetailsQuotesRequested event,
    Emitter<BookDetailsState> emit,
  ) async {
    final userBook = state.userBook;
    if (userBook == null) return;
    try {
      final quotes = await _quotes.forBook(userBook.id);
      emit(state.copyWith(quotes: quotes));
    } on Failure {
      // The section just shows no quotes.
    }
  }

  Future<void> _onQuoteSaved(
    BookDetailsQuoteSaved event,
    Emitter<BookDetailsState> emit,
  ) async {
    final userBook = state.userBook;
    final text = event.text.trim();
    if (userBook == null || text.isEmpty) return;
    final clipped = text.length > BookQuote.maxLength
        ? text.substring(0, BookQuote.maxLength)
        : text;
    final page = (event.page != null && event.page! > 0) ? event.page : null;
    final id = event.id;
    final current =
        id == null ? null : state.quotes.where((q) => q.id == id).firstOrNull;
    if (id != null && current == null) return;
    emit(
      state.copyWith(saveStatus: RequestStatus.loading, failure: () => null),
    );
    try {
      if (current == null) {
        final saved = await _quotes.add(
          userBookId: userBook.id,
          text: clipped,
          page: page,
        );
        emit(
          state.copyWith(
            quotes: [saved, ...state.quotes],
            saveStatus: RequestStatus.success,
          ),
        );
      } else {
        final saved = await _quotes.update(
          BookQuote(
            id: current.id,
            userBookId: current.userBookId,
            text: clipped,
            page: page,
            createdAt: current.createdAt,
          ),
        );
        emit(
          state.copyWith(
            quotes: [
              for (final q in state.quotes) q.id == current.id ? saved : q,
            ],
            saveStatus: RequestStatus.success,
          ),
        );
      }
    } on Failure catch (failure) {
      emit(
        state.copyWith(
          saveStatus: RequestStatus.failure,
          failure: () => failure,
        ),
      );
    }
  }

  /// Optimistic: the quote disappears at once and comes back on failure.
  Future<void> _onQuoteRemoved(
    BookDetailsQuoteRemoved event,
    Emitter<BookDetailsState> emit,
  ) async {
    final previous = state.quotes;
    if (!previous.any((q) => q.id == event.id)) return;
    emit(
      state.copyWith(
        quotes: [
          for (final q in previous)
            if (q.id != event.id) q,
        ],
        failure: () => null,
      ),
    );
    try {
      await _quotes.remove(event.id);
    } on Failure catch (failure) {
      emit(
        state.copyWith(
          quotes: previous,
          saveStatus: RequestStatus.failure,
          failure: () => failure,
        ),
      );
    }
  }

  /// Optimistic update: shows the change immediately, rolls back on failure.
  /// Returns whether the change was saved (false if nothing changed or the
  /// save failed).
  Future<bool> _edit(
    Emitter<BookDetailsState> emit,
    UserBook Function(UserBook) change,
  ) async {
    final previous = state.userBook;
    if (previous == null) return false;
    final updated = change(previous);
    if (updated == previous) return false;

    emit(
      state.copyWith(
        userBook: () => updated,
        saveStatus: RequestStatus.loading,
        failure: () => null,
      ),
    );
    try {
      final saved = await _library.update(updated);
      emit(
        state.copyWith(
          userBook: () => saved,
          saveStatus: RequestStatus.success,
        ),
      );
      return true;
    } on Failure catch (failure) {
      emit(
        state.copyWith(
          userBook: () => previous,
          saveStatus: RequestStatus.failure,
          failure: () => failure,
        ),
      );
      return false;
    }
  }

  Future<void> _onRemove(
    BookDetailsRemoveRequested event,
    Emitter<BookDetailsState> emit,
  ) async {
    final userBook = state.userBook;
    if (userBook == null) return;
    emit(
      state.copyWith(
        saveStatus: RequestStatus.loading,
        failure: () => null,
      ),
    );
    try {
      await _library.remove(userBook.id);
      emit(state.copyWith(saveStatus: RequestStatus.success, removed: true));
    } on Failure catch (failure) {
      emit(
        state.copyWith(
          saveStatus: RequestStatus.failure,
          failure: () => failure,
        ),
      );
    }
  }
}
