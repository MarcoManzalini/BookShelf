import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/request_status.dart';
import '../../../search/domain/entities/book.dart';
import '../../domain/entities/reading_status.dart';
import '../../domain/entities/shelf_names.dart';
import '../../domain/entities/sync_status.dart';
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
    on<LibraryShelfFilterChanged>(
      (event, emit) => emit(state.copyWith(shelfFilter: () => event.shelf)),
    );
    on<LibraryViewModeToggled>(
      (event, emit) => emit(
        state.copyWith(
          viewMode: state.viewMode == LibraryViewMode.shelf
              ? LibraryViewMode.swipe
              : LibraryViewMode.shelf,
        ),
      ),
    );
    on<LibrarySyncChanged>(_onSyncChanged);
    on<LibraryBookAdded>(_onBookAdded);
    on<LibraryCleared>(_onCleared);
  }

  final LibraryRepository _repository;
  final AddBookToLibrary _addBook;
  StreamSubscription<SyncStatus>? _syncSubscription;
  Timer? _retryTimer;

  /// While offline, the server is tried again on this schedule so queued
  /// edits go out soon after the connection is back.
  static const retryInterval = Duration(seconds: 30);

  void _listenToSync() {
    _syncSubscription ??=
        _repository.syncStatus.listen((sync) => add(LibrarySyncChanged(sync)));
  }

  void _onSyncChanged(LibrarySyncChanged event, Emitter<LibraryState> emit) {
    emit(
      state.copyWith(
        offline: event.sync.offline,
        pendingChanges: event.sync.pending,
      ),
    );
    if (event.sync.offline) {
      _retryTimer ??= Timer.periodic(
        retryInterval,
        (_) => add(const LibraryRefreshRequested()),
      );
    } else {
      _retryTimer?.cancel();
      _retryTimer = null;
    }
  }

  @override
  Future<void> close() {
    _retryTimer?.cancel();
    return _syncSubscription?.cancel().then((_) => super.close()) ??
        super.close();
  }

  Future<void> _onStarted(
    LibraryStarted event,
    Emitter<LibraryState> emit,
  ) async {
    _listenToSync();
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
    _retryTimer?.cancel();
    _retryTimer = null;
    emit(const LibraryState());
  }
}
