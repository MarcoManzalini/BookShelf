import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/bloc_transformers.dart';
import '../../../../core/utils/request_status.dart';
import '../../domain/entities/book.dart';
import '../../domain/repositories/book_search_repository.dart';

part 'search_event.dart';
part 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc(
    this._repository, {
    Duration debounce = AppConfig.searchDebounce,
  }) : super(const SearchState()) {
    on<SearchQueryChanged>(
      _onQueryChanged,
      transformer: debounceRestartable(debounce),
    );
    on<SearchNextPageRequested>(_onNextPage, transformer: droppable());
  }

  final BookSearchRepository _repository;

  Future<void> _onQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    final query = event.query.trim();
    if (query.isEmpty) {
      emit(const SearchState());
      return;
    }

    emit(SearchState(query: query, status: RequestStatus.loading));
    try {
      final result = await _repository.search(query);
      emit(
        SearchState(
          query: query,
          status: RequestStatus.success,
          books: result.books,
          page: result.page,
          hasMore: result.hasMore,
        ),
      );
    } on Failure catch (failure) {
      emit(
        SearchState(
          query: query,
          status: RequestStatus.failure,
          failure: failure,
        ),
      );
    }
  }

  Future<void> _onNextPage(
    SearchNextPageRequested event,
    Emitter<SearchState> emit,
  ) async {
    if (!state.status.isSuccess || !state.hasMore || state.isLoadingMore) {
      return;
    }
    final query = state.query;
    emit(state.copyWith(isLoadingMore: true, loadMoreFailure: () => null));
    try {
      final result = await _repository.search(query, page: state.page + 1);
      // The query may have changed while this page was loading.
      if (state.query != query) return;
      final known = {for (final b in state.books) b.externalId};
      emit(
        state.copyWith(
          books: [
            ...state.books,
            ...result.books.where((b) => !known.contains(b.externalId)),
          ],
          page: result.page,
          hasMore: result.hasMore,
          isLoadingMore: false,
        ),
      );
    } on Failure catch (failure) {
      if (state.query != query) return;
      emit(
        state.copyWith(
          isLoadingMore: false,
          loadMoreFailure: () => failure,
        ),
      );
    }
  }
}
