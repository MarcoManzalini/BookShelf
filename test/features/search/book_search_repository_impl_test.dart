import 'package:bookshelf/core/errors/failure.dart';
import 'package:bookshelf/features/search/data/datasources/book_remote_data_source.dart';
import 'package:bookshelf/features/search/data/repositories/book_search_repository_impl.dart';
import 'package:bookshelf/features/search/domain/entities/book_search_page.dart';
import 'package:bookshelf/features/search/domain/entities/explore_section.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures.dart';

class MockRemote extends Mock implements BookRemoteDataSource {}

void main() {
  late MockRemote remote;
  late DateTime now;

  final page = BookSearchPage(
    books: [buildBook()],
    page: 1,
    hasMore: false,
  );

  setUpAll(() => registerFallbackValue(ExploreSection.popular));

  setUp(() {
    remote = MockRemote();
    now = DateTime(2026, 1, 1);
    when(() => remote.search(any(), page: any(named: 'page')))
        .thenAnswer((_) async => page);
  });

  BookSearchRepositoryImpl build({int cacheSize = 40}) =>
      BookSearchRepositoryImpl(remote, now: () => now, cacheSize: cacheSize);

  group('normalizeQuery', () {
    test('collapses whitespace', () {
      expect(
        BookSearchRepositoryImpl.normalizeQuery('  the   great\tgatsby '),
        'the great gatsby',
      );
    });

    test('turns ISBNs into exact isbn: queries', () {
      expect(
        BookSearchRepositoryImpl.normalizeQuery('978-0-441-17271-9'),
        'isbn:9780441172719',
      );
      expect(
        BookSearchRepositoryImpl.normalizeQuery('0 441 17271 X'),
        'isbn:044117271X',
      );
    });

    test('leaves other numbers alone', () {
      expect(BookSearchRepositoryImpl.normalizeQuery('1984'), '1984');
      expect(
        BookSearchRepositoryImpl.normalizeQuery('fahrenheit 451'),
        'fahrenheit 451',
      );
    });
  });

  group('search cache', () {
    test('repeated queries hit the network once, ignoring case and spacing',
        () async {
      final repo = build();
      await repo.search('Dune');
      await repo.search('  dune ');
      verify(() => remote.search('Dune', page: 1)).called(1);
      verifyNever(() => remote.search('dune', page: 1));
    });

    test('pages are cached separately', () async {
      final repo = build();
      await repo.search('dune');
      await repo.search('dune', page: 2);
      verify(() => remote.search('dune', page: any(named: 'page'))).called(2);
    });

    test('entries expire after the ttl', () async {
      final repo = build();
      await repo.search('dune');
      now = now.add(const Duration(minutes: 11));
      await repo.search('dune');
      verify(() => remote.search('dune', page: 1)).called(2);
    });

    test('evicts the least recently used entry', () async {
      final repo = build(cacheSize: 2);
      await repo.search('a1');
      await repo.search('b2');
      await repo.search('a1'); // a1 is now the most recent
      await repo.search('c3'); // evicts b2
      clearInteractions(remote);

      await repo.search('a1');
      await repo.search('b2');
      verifyNever(() => remote.search('a1', page: 1));
      verify(() => remote.search('b2', page: 1)).called(1);
    });

    test('failures are not cached and are mapped to Failure', () async {
      when(() => remote.search(any(), page: any(named: 'page'))).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      final repo = build();
      await expectLater(
        repo.search('dune'),
        throwsA(const Failure(FailureCode.timeout)),
      );

      when(() => remote.search(any(), page: any(named: 'page')))
          .thenAnswer((_) async => page);
      expect(await repo.search('dune'), page);
    });
  });

  group('related books', () {
    test('books by author exclude the current book', () async {
      when(() => remote.fetchBooksByAuthor('OL9A', limit: any(named: 'limit')))
          .thenAnswer(
        (_) async => [buildBook(id: 'OL1W'), buildBook(id: 'OL2W')],
      );
      final books = await build().getBooksByAuthor('OL9A', exclude: 'OL1W');
      expect(books.map((b) => b.externalId), ['OL2W']);
    });

    test('similar books use two subjects and skip the same author', () async {
      final book = buildBook().copyWith(
        subjects: const ['Science fiction', 'Ecology', 'Deserts'],
        authorKeys: const ['OL9A'],
      );
      when(
        () => remote.fetchBooksBySubjects(any(), limit: any(named: 'limit')),
      ).thenAnswer(
        (_) async => [
          buildBook(id: 'OL1W'),
          buildBook(id: 'OL2W').copyWith(authorKeys: const ['OL9A']),
          buildBook(id: 'OL3W').copyWith(authorKeys: const ['OL7A']),
        ],
      );

      final books = await build().getSimilarBooks(book);

      expect(books.map((b) => b.externalId), ['OL3W']);
      verify(
        () => remote.fetchBooksBySubjects(
          ['Science fiction', 'Ecology'],
          limit: any(named: 'limit'),
        ),
      );
    });

    test('no subjects means no request', () async {
      expect(await build().getSimilarBooks(buildBook()), isEmpty);
      verifyNever(
        () => remote.fetchBooksBySubjects(any(), limit: any(named: 'limit')),
      );
    });
  });

  group('explore sections', () {
    void stubExplore(List<dynamic> books) => when(
          () => remote.fetchExplore(any(), limit: any(named: 'limit')),
        ).thenAnswer((_) async => books.cast());

    final withCover = buildBook(id: 'OL1W').copyWith(coverUrl: 'cover');
    final noCover = buildBook(id: 'OL2W');

    test('keeps only books with a cover, up to the limit', () async {
      stubExplore([noCover, withCover]);
      final books = await build().getExploreSection(
        ExploreSection.bestSellers,
        limit: 1,
      );
      expect(books, [withCover]);
    });

    test('asks for a few extra books to compensate the filtered ones',
        () async {
      stubExplore([withCover]);
      await build().getExploreSection(ExploreSection.popular, limit: 12);
      verify(() => remote.fetchExplore(ExploreSection.popular, limit: 18))
          .called(1);
    });

    test('is cached until refreshed', () async {
      stubExplore([withCover]);
      final repo = build();
      await repo.getExploreSection(ExploreSection.popular);
      await repo.getExploreSection(ExploreSection.popular);
      verify(() => remote.fetchExplore(any(), limit: any(named: 'limit')))
          .called(1);

      await repo.getExploreSection(ExploreSection.popular, refresh: true);
      verify(() => remote.fetchExplore(any(), limit: any(named: 'limit')))
          .called(1);
    });

    test('maps network errors to Failure', () async {
      when(() => remote.fetchExplore(any(), limit: any(named: 'limit')))
          .thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.connectionError,
        ),
      );
      await expectLater(
        build().getExploreSection(ExploreSection.bestSellers),
        throwsA(const Failure(FailureCode.network)),
      );
    });
  });

  group('findByIsbn', () {
    test('searches by isbn and returns the first match', () async {
      final first = buildBook(id: 'OL1W');
      when(() => remote.search('isbn:9780441172719', page: 1)).thenAnswer(
        (_) async => BookSearchPage(
          books: [first, buildBook(id: 'OL2W')],
          page: 1,
          hasMore: false,
        ),
      );
      expect(await build().findByIsbn('9780441172719'), first);
    });

    test('returns null when nothing matches', () async {
      when(() => remote.search(any(), page: any(named: 'page'))).thenAnswer(
        (_) async => const BookSearchPage(books: [], page: 1, hasMore: false),
      );
      expect(await build().findByIsbn('9780441172719'), isNull);
    });
  });
}
