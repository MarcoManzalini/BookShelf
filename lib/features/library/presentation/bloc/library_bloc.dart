import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/request_status.dart';
import '../../../search/domain/entities/book.dart';
import '../../domain/entities/reading_status.dart';
import '../../domain/entities/user_book.dart';
import '../../domain/repositories/library_repository.dart';
import '../../domain/usecases/add_book_to_library.dart';

part 'library_event.dart';
part 'library_state.dart';

class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  LibraryBloc(this._repository, this._addBook) : super(const LibraryState()) {
    on<LibraryStarted>(_onStarted, transformer: restartable());
    on<LibraryRefreshRequested>(_onRefresh, transformer: droppable());
    on<LibraryFilterChanged>(
      (event, emit) => emit(state.copyWith(filter: event.filter)),
    );
    on<LibraryViewModeToggled>(
      (event, emit) => emit(
        state.copyWith(
          viewMode: state.viewMode == LibraryViewMode.list
              ? LibraryViewMode.grid
              : LibraryViewMode.list,
        ),
      ),
    );
    on<LibraryBookAdded>(_onBookAdded);
    on<LibraryCleared>(_onCleared);
  }

  final LibraryRepository _repository;
  final AddBookToLibrary _addBook;

  Future<void> _onStarted(
    LibraryStarted event,
    Emitter<LibraryState> emit,
  ) async {
    emit(state.copyWith(status: RequestStatus.loading, failure: () => null));
    try {
      final books = await _repository.fetchAll();
      emit(state.copyWith(status: RequestStatus.success, books: books));
    } on Failure catch (failure) {
      emit(
        state.copyWith(
          status: RequestStatus.failure,
          failure: () => failure,
        ),
      );
    }
    // Keeps the list in sync with edits made from the details page.
    await emit.forEach<List<UserBook>>(
      _repository.books,
      onData: (books) =>
          state.copyWith(books: books, status: RequestStatus.success),
    );
  }

  Future<void> _onRefresh(
    LibraryRefreshRequested event,
    Emitter<LibraryState> emit,
  ) async {
    emit(state.copyWith(refreshing: true, actionFailure: () => null));
    try {
      final books = await _repository.fetchAll();
      emit(
        state.copyWith(
          refreshing: false,
          status: RequestStatus.success,
          books: books,
          failure: () => null,
        ),
      );
    } on Failure catch (failure) {
      emit(
        state.copyWith(
          refreshing: false,
          actionFailure: () => failure,
        ),
      );
    }
  }

  Future<void> _onBookAdded(
    LibraryBookAdded event,
    Emitter<LibraryState> emit,
  ) async {
    final id = event.book.externalId;
    if (state.addingIds.contains(id) || state.containsExternalId(id)) return;

    emit(
      state.copyWith(
        addingIds: {...state.addingIds, id},
        actionFailure: () => null,
      ),
    );
    try {
      await _addBook(event.book, event.status);
      emit(
        state.copyWith(
          addingIds: {...state.addingIds}..remove(id),
        ),
      );
    } on Failure catch (failure) {
      emit(
        state.copyWith(
          addingIds: {...state.addingIds}..remove(id),
          actionFailure: () => failure,
        ),
      );
    }
  }

  void _onCleared(LibraryCleared event, Emitter<LibraryState> emit) {
    _repository.clear();
    emit(const LibraryState());
  }
}
