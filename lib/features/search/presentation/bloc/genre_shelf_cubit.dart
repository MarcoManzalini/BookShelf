import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/request_status.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/explore_genre.dart';
import '../../domain/repositories/book_search_repository.dart';

/// The "Top rated by genre" shelf: one genre at a time, chosen with chips.
class GenreShelfCubit extends Cubit<GenreShelfState> {
  GenreShelfCubit(this._repository) : super(const GenreShelfState());

  final BookSearchRepository _repository;

  static const shelfLimit = 20;

  Future<void> load({bool refresh = false}) => _load(state.genre, refresh);

  Future<void> select(ExploreGenre genre) {
    if (genre == state.genre && !state.status.isFailure) return Future.value();
    return _load(genre, false);
  }

  Future<void> _load(ExploreGenre genre, bool refresh) async {
    emit(GenreShelfState(genre: genre, status: RequestStatus.loading));
    try {
      final books = await _repository.getTopByGenre(
        genre,
        limit: shelfLimit,
        refresh: refresh,
      );
      // A quicker tap on another chip already replaced this request.
      if (state.genre != genre) return;
      emit(
        GenreShelfState(
          genre: genre,
          status: RequestStatus.success,
          books: books,
        ),
      );
    } on Failure catch (failure) {
      if (state.genre != genre) return;
      emit(
        GenreShelfState(
          genre: genre,
          status: RequestStatus.failure,
          failure: failure,
        ),
      );
    }
  }
}

class GenreShelfState extends Equatable {
  const GenreShelfState({
    this.genre = ExploreGenre.fantasy,
    this.status = RequestStatus.initial,
    this.books = const [],
    this.failure,
  });

  final ExploreGenre genre;
  final RequestStatus status;
  final List<Book> books;
  final Failure? failure;

  @override
  List<Object?> get props => [genre, status, books, failure];
}
