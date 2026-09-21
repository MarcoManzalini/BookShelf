import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/bloc_transformers.dart';
import '../../../../core/utils/request_status.dart';
import '../../domain/entities/book.dart';
import '../../data/search_language_preference.dart';
import '../../domain/repositories/book_search_repository.dart';

part 'search_event.dart';
part 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc(
    this._repository, {
    Duration debounce = AppConfig.searchDebounce,
    SearchLanguagePreference? languagePreference,
  })  : _languagePreference = languagePreference,
        super(SearchState(language: languagePreference?.load())) {
    on<SearchQueryChanged>(
      _onQueryChanged,
      transformer: debounceRestartable(debounce),
    );
    on<SearchLanguageChanged>(_onLanguageChanged);
    on<SearchNextPageRequested>(_onNextPage, transformer: droppable());
  }

  final BookSearchRepository _repository;
  final SearchLanguagePreference? _languagePreference;

  Future<void> _onQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    final query = event.query.trim();
    final language = state.language;
    if (query.length < AppConfig.searchMinChars) {
      emit(SearchState(language: language));
      return;
    }
    await _search(query, language, emit);
  }

  Future<void> _search(
    String query,
    String? language,
    Emitter<SearchState> emit,
  ) async {
    emit(
      SearchState(
        query: query,
        status: RequestStatus.loading,
        language: language,
      ),
    );
    try {
      final result = await _repository.search(query, language: language);
      emit(
        SearchState(
          query: query,
          status: RequestStatus.success,
          books: result.books,
          page: result.page,
          hasMore: result.hasMore,
          language: language,
        ),
      );
    } on Failure catch (failure) {
      emit(
        SearchState(
          query: query,
          status: RequestStatus.failure,
          failure: failure,
          language: language,
        ),
      );
    }
  }

  Future<void> _onLanguageChanged(
    SearchLanguageChanged event,
    Emitter<SearchState> emit,
  ) async {
    if (event.language == state.language) return;
    await _languagePreference?.save(event.language);
    final query = state.query;
    if (query.isEmpty) {
      emit(state.copyWith(language: () => event.language));
      return;
    }
    await _search(query, event.language, emit);
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
      final result = await _repository.search(
        query,
        page: state.page + 1,
        language: state.language,
      );
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
