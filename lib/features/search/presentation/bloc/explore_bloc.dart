import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/request_status.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/explore_section.dart';
import '../../domain/repositories/book_search_repository.dart';

part 'explore_event.dart';
part 'explore_state.dart';

/// Loads the Explore shelves side by side: each one fills in as soon as its
/// own request completes, and a failing shelf never blocks the others.
class ExploreBloc extends Bloc<ExploreEvent, ExploreState> {
  ExploreBloc(this._repository) : super(const ExploreState()) {
    on<ExploreStarted>(
      (event, emit) => _loadAll(emit, refresh: false),
      transformer: droppable(),
    );
    on<ExploreRefreshRequested>(
      (event, emit) => _loadAll(emit, refresh: true),
      transformer: droppable(),
    );
  }

  final BookSearchRepository _repository;

  Future<void> _loadAll(
    Emitter<ExploreState> emit, {
    required bool refresh,
  }) async {
    // Shelves that already have books keep showing them while refreshing.
    emit(
      state.copyWithSections(
        {
          for (final section in ExploreSection.values)
            if (state.of(section).books.isEmpty)
              section: const ExploreShelf(status: RequestStatus.loading),
        },
        refreshing: true,
      ),
    );
    await Future.wait([
      for (final section in ExploreSection.values)
        _load(section, emit, refresh: refresh),
    ]);
    emit(state.copyWithSections(const {}, refreshing: false));
  }

  Future<void> _load(
    ExploreSection section,
    Emitter<ExploreState> emit, {
    required bool refresh,
  }) async {
    try {
      final books = await _repository.getExploreSection(
        section,
        refresh: refresh,
      );
      emit(
        state.copyWithSections({
          section: ExploreShelf(status: RequestStatus.success, books: books),
        }),
      );
    } on Failure catch (failure) {
      final previous = state.of(section).books;
      emit(
        state.copyWithSections({
          section: previous.isEmpty
              ? ExploreShelf(status: RequestStatus.failure, failure: failure)
              : ExploreShelf(status: RequestStatus.success, books: previous),
        }),
      );
    }
  }
}
