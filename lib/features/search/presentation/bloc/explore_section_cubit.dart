import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/request_status.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/explore_section.dart';
import '../../domain/repositories/book_search_repository.dart';

/// The full list behind a shelf's "View all".
class ExploreSectionCubit extends Cubit<ExploreSectionState> {
  ExploreSectionCubit(this._repository, this.section)
      : super(const ExploreSectionState());

  final BookSearchRepository _repository;
  final ExploreSection section;

  static const pageLimit = 40;

  Future<void> load() async {
    emit(const ExploreSectionState(status: RequestStatus.loading));
    try {
      final books = await _repository.getExploreSection(
        section,
        limit: pageLimit,
      );
      emit(ExploreSectionState(status: RequestStatus.success, books: books));
    } on Failure catch (failure) {
      emit(
        ExploreSectionState(status: RequestStatus.failure, failure: failure),
      );
    }
  }
}

class ExploreSectionState extends Equatable {
  const ExploreSectionState({
    this.status = RequestStatus.initial,
    this.books = const [],
    this.failure,
  });

  final RequestStatus status;
  final List<Book> books;
  final Failure? failure;

  @override
  List<Object?> get props => [status, books, failure];
}
