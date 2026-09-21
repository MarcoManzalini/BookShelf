import 'package:bookshelf/features/search/data/repositories/book_search_repository_impl.dart';
import 'package:bookshelf/features/search/data/datasources/book_remote_data_source.dart';
import 'package:bookshelf/features/search/domain/entities/book.dart';
import 'package:bookshelf/features/search/domain/entities/book_ranking.dart';
import 'package:bookshelf/features/search/domain/entities/explore_genre.dart';
import 'package:bookshelf/features/search/domain/entities/explore_section.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements BookRemoteDataSource {}

Book _book(String id, double? average, int? votes) => Book(
      externalId: id,
      title: id,
      coverUrl: 'https://covers.openlibrary.org/b/id/1-L.jpg',
      ratingAverage: average,
      ratingsCount: votes,
    );

void main() {
  setUpAll(() {
    registerFallbackValue(ExploreGenre.fantasy);
    registerFallbackValue(ExploreSection.popular);
  });

  group('BookRanking.rank', () {
    test('a lone 5-star vote does not beat 4.8 with fifty votes', () {
      final ranked = BookRanking.rank([
        _book('one-vote', 5.0, 2),
        _book('solid', 4.8, 50),
        _book('average', 3.9, 400),
      ]);

      expect(ranked.map((b) => b.externalId), ['solid', 'average', 'one-vote']);
    });

    test('more votes win at equal average', () {
      final ranked = BookRanking.rank([
        _book('few', 4.5, 10),
        _book('many', 4.5, 500),
        _book('other', 3.0, 100),
      ]);

      expect(ranked.first.externalId, 'many');
    });

    test('drops unrated books and keeps input order on ties', () {
      final ranked = BookRanking.rank([
        _book('b', 4.0, 40),
        _book('none', null, null),
        _book('zero', 4.9, 0),
        _book('a', 4.0, 40),
      ]);

      expect(ranked.map((b) => b.externalId), ['b', 'a']);
    });

    test('empty pool ranks to nothing', () {
      expect(BookRanking.rank(const []), isEmpty);
    });
  });

  group('getTopByGenre', () {
    test('keeps the popularity order and serves the second call from cache',
        () async {
      final remote = _MockRemote();
      when(() => remote.fetchTopByGenre(any(), limit: any(named: 'limit')))
          .thenAnswer(
        (_) async => [_book('famous', 4.0, 900), _book('niche', 4.8, 50)],
      );
      final repo = BookSearchRepositoryImpl(remote);

      final first = await repo.getTopByGenre(ExploreGenre.fantasy);
      final second = await repo.getTopByGenre(ExploreGenre.fantasy);

      expect(first.map((b) => b.externalId), ['famous', 'niche']);
      expect(second, first);
      verify(() => remote.fetchTopByGenre(ExploreGenre.fantasy, limit: 20))
          .called(1);
    });
  });

  group('popular section', () {
    test('ranks on votes and quantity, not on the plain average', () async {
      final remote = _MockRemote();
      when(() => remote.fetchExplore(any(), limit: any(named: 'limit')))
          .thenAnswer(
        (_) async => [_book('one-vote', 5.0, 2), _book('solid', 4.8, 50)],
      );
      final repo = BookSearchRepositoryImpl(remote);

      final books = await repo.getExploreSection(ExploreSection.popular);

      expect(books.map((b) => b.externalId), ['solid', 'one-vote']);
    });

    test('best sellers keep the order the server gave', () async {
      final remote = _MockRemote();
      when(() => remote.fetchExplore(any(), limit: any(named: 'limit')))
          .thenAnswer(
        (_) async => [_book('first', 3.0, 5), _book('second', 5.0, 500)],
      );
      final repo = BookSearchRepositoryImpl(remote);

      final books = await repo.getExploreSection(ExploreSection.bestSellers);

      expect(books.map((b) => b.externalId), ['first', 'second']);
    });
  });
}
