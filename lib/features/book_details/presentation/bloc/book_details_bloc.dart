import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/request_status.dart';
import '../../../library/domain/entities/reading_status.dart';
import '../../../library/domain/entities/user_book.dart';
import '../../../library/domain/repositories/library_repository.dart';
import '../../../library/domain/usecases/add_book_to_library.dart';
import '../../../search/domain/entities/book.dart';
import '../../../search/domain/repositories/book_search_repository.dart';

part 'book_details_event.dart';
part 'book_details_state.dart';

class BookDetailsBloc extends Bloc<BookDetailsEvent, BookDetailsState> {
  BookDetailsBloc({
    required LibraryRepository libraryRepository,
    required BookSearchRepository searchRepository,
    required AddBookToLibrary addBook,
  })  : _library = libraryRepository,
        _search = searchRepository,
        _addBook = addBook,
        super(const BookDetailsState()) {
    on<BookDetailsLibraryRequested>(_onLibraryRequested);
    on<BookDetailsPreviewRequested>(_onPreviewRequested);
    on<BookDetailsAddRequested>(_onAddRequested, transformer: droppable());
    on<BookDetailsStatusChanged>(
      (e, emit) => _edit(emit, (b) => b.withStatus(e.status)),
      transformer: sequential(),
    );
    on<BookDetailsProgressChanged>(
      (e, emit) => _edit(emit, (b) => b.withProgress(e.page)),
      transformer: sequential(),
    );
    on<BookDetailsRatingChanged>(
      (e, emit) => _edit(emit, (b) => b.copyWith(rating: () => e.rating)),
      transformer: sequential(),
    );
    on<BookDetailsNotesChanged>(
      (e, emit) {
        final trimmed = e.notes.trim();
        return _edit(
          emit,
          (b) => b.copyWith(notes: () => trimmed.isEmpty ? null : trimmed),
        );
      },
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
    on<BookDetailsRemoveRequested>(_onRemove, transformer: droppable());
  }

  final LibraryRepository _library;
  final BookSearchRepository _search;
  final AddBookToLibrary _addBook;

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
      return;
    }

    emit(state.copyWith(status: RequestStatus.success, book: event.book));
    if (event.book.description != null) return;
    // Description and extra images are best effort: the preview is already
    // usable without them.
    try {
      final detailed = await _search.getBookDetails(event.book);
      if (!state.isInLibrary) emit(state.copyWith(book: detailed));
    } on Failure {
      // Keep the basic preview.
    }
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
          book: saved.book,
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

  /// Optimistic update: shows the change immediately, rolls back on failure.
  Future<void> _edit(
    Emitter<BookDetailsState> emit,
    UserBook Function(UserBook) change,
  ) async {
    final previous = state.userBook;
    if (previous == null) return;
    final updated = change(previous);
    if (updated == previous) return;

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
    } on Failure catch (failure) {
      emit(
        state.copyWith(
          userBook: () => previous,
          saveStatus: RequestStatus.failure,
          failure: () => failure,
        ),
      );
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
