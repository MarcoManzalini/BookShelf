import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/request_status.dart';
import '../../../search/domain/entities/book.dart';
import '../../../search/domain/entities/book_edition.dart';
import '../../../search/domain/repositories/book_search_repository.dart';

class EditionsState extends Equatable {
  const EditionsState({
    this.status = RequestStatus.initial,
    this.editions = const [],
    this.failure,
  });

  final RequestStatus status;
  final List<BookEdition> editions;
  final Failure? failure;

  /// Languages present, most common first.
  List<String> get languages {
    final counts = <String, int>{};
    for (final e in editions) {
      final language = e.language;
      if (language != null) counts[language] = (counts[language] ?? 0) + 1;
    }
    return counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
  }

  @override
  List<Object?> get props => [status, editions, failure];
}

/// Loads the editions of one book for the edition picker.
class EditionsCubit extends Cubit<EditionsState> {
  EditionsCubit(this._repository, this.book) : super(const EditionsState());

  final BookSearchRepository _repository;
  final Book book;

  Future<void> load() async {
    emit(const EditionsState(status: RequestStatus.loading));
    try {
      final editions = await _repository.getEditions(book);
      emit(EditionsState(status: RequestStatus.success, editions: editions));
    } on Failure catch (failure) {
      emit(EditionsState(status: RequestStatus.failure, failure: failure));
    }
  }
}
