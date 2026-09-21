import 'package:bloc/bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/request_status.dart';
import '../../domain/entities/explore_genre.dart';
import '../../domain/repositories/book_search_repository.dart';
import 'explore_section_cubit.dart';

/// The full list behind the genre shelf's "View all".
class ExploreGenreCubit extends Cubit<ExploreSectionState> {
  ExploreGenreCubit(this._repository, this.genre)
      : super(const ExploreSectionState());

  final BookSearchRepository _repository;
  final ExploreGenre genre;

  static const pageLimit = ExploreSectionCubit.pageLimit;

  Future<void> load() async {
    emit(const ExploreSectionState(status: RequestStatus.loading));
    try {
      final books = await _repository.getTopByGenre(genre, limit: pageLimit);
      emit(ExploreSectionState(status: RequestStatus.success, books: books));
    } on Failure catch (failure) {
      emit(
        ExploreSectionState(status: RequestStatus.failure, failure: failure),
      );
    }
  }
}
