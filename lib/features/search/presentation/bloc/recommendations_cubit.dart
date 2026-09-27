import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/request_status.dart';
import '../../../library/domain/entities/user_book.dart';
import '../../../library/domain/repositories/library_repository.dart';
import '../../domain/entities/book.dart';
import '../../domain/repositories/book_search_repository.dart';

/// "Based on your latest reads": one list merging the suggestions for the
/// last few books the reader finished.
class RecommendationsCubit extends Cubit<RecommendationsState> {
  RecommendationsCubit(this._search, this._library)
      : super(const RecommendationsState()) {
    // The library may still be loading when the page opens, and it changes as
    // books get finished: reload only when the books we recommend from change.
    _subscription = _library.books.listen((_) {
      if (!_sameSeeds(seedsOf(_library.cachedBooks))) unawaited(load());
    });
  }

  final BookSearchRepository _search;
  final LibraryRepository _library;
  StreamSubscription<List<UserBook>>? _subscription;
  List<String> _seedIds = const [];

  /// How many recently finished books the suggestions come from.
  static const seedCount = 3;

  /// Books in the merged list.
  static const shelfLimit = 20;

  /// The last [seedCount] finished books, most recent first. Books without
  /// subjects cannot be matched to anything, so they are skipped.
  static List<UserBook> seedsOf(List<UserBook> library) {
    final read = library
        .where(
          (b) => b.readCount > 0 && b.book.subjects.isNotEmpty,
        )
        .toList()
      ..sort(
        (a, b) => (b.finishedAt ?? b.createdAt)
            .compareTo(a.finishedAt ?? a.createdAt),
      );
    return read.take(seedCount).toList();
  }

  /// Merges one suggestion list per source book into a single list, each book
  /// once. Lists are interleaved, so every source weighs the same, and a book
  /// suggested by several sources moves ahead of the rest.
  static List<Book> merge(List<List<Book>> lists, {required int limit}) {
    final votes = <String, int>{};
    final order = <Book>[];
    final longest = lists.fold<int>(0, (m, l) => l.length > m ? l.length : m);
    for (var i = 0; i < longest; i++) {
      for (final list in lists) {
        if (i >= list.length) continue;
        final book = list[i];
        if (votes.update(book.externalId, (v) => v + 1, ifAbsent: () => 1) ==
            1) {
          order.add(book);
        }
      }
    }
    // Stable: equal votes keep the interleaved order.
    final indexed = order.indexed.toList()
      ..sort((a, b) {
        final byVotes =
            votes[b.$2.externalId]!.compareTo(votes[a.$2.externalId]!);
        return byVotes != 0 ? byVotes : a.$1.compareTo(b.$1);
      });
    return [for (final e in indexed.take(limit)) e.$2];
  }

  bool _sameSeeds(List<UserBook> seeds) {
    final ids = [for (final s in seeds) s.id];
    if (ids.length != _seedIds.length) return false;
    for (var i = 0; i < ids.length; i++) {
      if (ids[i] != _seedIds[i]) return false;
    }
    return true;
  }

  Future<void> load() async {
    final seeds = seedsOf(_library.cachedBooks);
    _seedIds = [for (final s in seeds) s.id];
    if (seeds.isEmpty) {
      emit(const RecommendationsState(status: RequestStatus.success));
      return;
    }
    if (state.books.isEmpty) {
      emit(const RecommendationsState(status: RequestStatus.loading));
    }
    try {
      final results = await Future.wait([
        for (final seed in seeds) _search.getSimilarBooks(seed.book),
      ]);
      // A newer load (different seeds) superseded this one.
      if (isClosed || _seedIds.join() != [for (final s in seeds) s.id].join()) {
        return;
      }
      emit(
        RecommendationsState(
          status: RequestStatus.success,
          books: merge(
            [
              for (final books in results)
                [
                  for (final book in books)
                    // Only new suggestions, with artwork.
                    if (book.coverUrl != null &&
                        _library.findCachedByExternalId(book.externalId) ==
                            null)
                      book,
                ],
            ],
            limit: shelfLimit,
          ),
        ),
      );
    } on Failure catch (failure) {
      // Suggestions are a bonus: keep what is on screen, hide on first load.
      emit(
        state.books.isEmpty
            ? RecommendationsState(
                status: RequestStatus.failure,
                failure: failure,
              )
            : state,
      );
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

class RecommendationsState extends Equatable {
  const RecommendationsState({
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
