import 'package:bloc_test/bloc_test.dart';
import 'package:bookshelf/core/utils/request_status.dart';
import 'package:bookshelf/features/book_details/presentation/bloc/book_details_bloc.dart';
import 'package:bookshelf/features/library/domain/entities/user_book.dart';
import 'package:bookshelf/features/search/data/datasources/book_remote_data_source.dart';
import 'package:bookshelf/features/search/data/mappers/open_library_mapper.dart';
import 'package:bookshelf/features/search/data/repositories/book_search_repository_impl.dart';
import 'package:bookshelf/features/search/data/search_language_preference.dart';
import 'package:bookshelf/features/search/domain/entities/book_edition.dart';
import 'package:bookshelf/features/search/domain/entities/book_search_page.dart';
import 'package:bookshelf/features/search/presentation/bloc/search_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';

class MockRemote extends Mock implements BookRemoteDataSource {}

void main() {
  group('OpenLibraryMapper.editionFromJson', () {
    test('maps a complete edition', () {
      final edition = OpenLibraryMapper.editionFromJson({
        'key': '/books/OL62445412M',
        'title': 'Dune',
        'publishers': ['Nemira Publishing House'],
        'publish_date': 'March 1, 2021',
        'number_of_pages': 734,
        'isbn_13': ['9786064312617'],
        'isbn_10': ['6064312612'],
        'languages': [
          {'key': '/languages/ita'},
        ],
        'covers': [-1, 15246488],
        'physical_format': 'Paperback',
      })!;

      expect(edition.key, 'OL62445412M');
      expect(edition.publisher, 'Nemira Publishing House');
      expect(edition.publishedYear, 2021);
      expect(edition.pageCount, 734);
      expect(edition.isbn, '9786064312617', reason: 'prefers ISBN-13');
      expect(edition.language, 'ita');
      expect(edition.coverUrl, OpenLibraryMapper.coverUrl(15246488));
      expect(edition.format, 'Paperback');
    });

    test('tolerates missing fields and rejects entries without a key', () {
      final edition = OpenLibraryMapper.editionFromJson({
        'key': '/books/OL1M',
        'publish_date': 'n.d.',
      })!;
      expect(edition.publishedYear, isNull);
      expect(edition.pageCount, isNull);
      expect(edition.isbn, isNull);
      expect(edition.completeness, 0);
      expect(OpenLibraryMapper.editionFromJson({'title': 'x'}), isNull);
    });
  });

  group('BookEdition.applyTo', () {
    const edition = BookEdition(
      key: 'OL9M',
      publisher: 'Mondadori',
      publishedYear: 2018,
      pageCount: 700,
      isbn: '9788804123456',
      language: 'ita',
    );

    test('overrides the book details it knows and keeps the rest', () {
      final book = buildBook(pageCount: 400).copyWith(
        coverUrl: 'cover',
        description: 'Spice.',
      );
      final updated = edition.applyTo(book);

      expect(updated.editionKey, 'OL9M');
      expect(updated.pageCount, 700);
      expect(updated.publisher, 'Mondadori');
      expect(updated.language, 'ita');
      expect(updated.coverUrl, 'cover', reason: 'edition has no cover');
      expect(updated.description, 'Spice.');
      expect(updated.title, book.title);
    });

    test('a saved book takes the edition', () {
      final updated = buildUserBook().withEdition(edition);
      expect(updated.book.pageCount, 700);
      expect(updated.id, buildUserBook().id);
    });
  });

  group('repository', () {
    late MockRemote remote;
    final page = BookSearchPage(books: [buildBook()], page: 1, hasMore: false);

    setUp(() {
      remote = MockRemote();
      when(() => remote.search(any(), page: any(named: 'page')))
          .thenAnswer((_) async => page);
    });

    test('scopes the query to a language', () async {
      await BookSearchRepositoryImpl(remote).search('dune', language: 'ita');
      verify(() => remote.search('(dune) AND language:ita', page: 1)).called(1);
    });

    test('caches per language', () async {
      final repo = BookSearchRepositoryImpl(remote);
      await repo.search('dune');
      await repo.search('dune', language: 'ita');
      await repo.search('dune', language: 'ita');
      verify(() => remote.search(any(), page: any(named: 'page'))).called(2);
    });

    test('never scopes an ISBN lookup', () async {
      await BookSearchRepositoryImpl(remote)
          .search('978-0-441-17271-9', language: 'ita');
      verify(() => remote.search('isbn:9780441172719', page: 1)).called(1);
    });

    test('lists the most complete editions first, keeping ties stable',
        () async {
      when(() => remote.fetchEditions('OL1W')).thenAnswer(
        (_) async => const [
          BookEdition(key: 'bare1'),
          BookEdition(key: 'full', isbn: '1', pageCount: 5, publisher: 'p'),
          BookEdition(key: 'bare2'),
          BookEdition(key: 'some', isbn: '2'),
        ],
      );
      final editions =
          await BookSearchRepositoryImpl(remote).getEditions(buildBook());
      expect(editions.map((e) => e.key), ['full', 'some', 'bare1', 'bare2']);
    });
  });

  group('SearchBloc language', () {
    late MockBookSearchRepository repository;
    const settle = Duration(milliseconds: 120);

    setUp(() => repository = MockBookSearchRepository());

    SearchBloc build([SearchLanguagePreference? preference]) => SearchBloc(
          repository,
          debounce: const Duration(milliseconds: 20),
          languagePreference: preference,
        );

    blocTest<SearchBloc, SearchState>(
      'changing language re-runs the current search with it',
      setUp: () {
        when(() => repository.search('dune', language: any(named: 'language')))
            .thenAnswer(
          (_) async =>
              BookSearchPage(books: [buildBook()], page: 1, hasMore: false),
        );
      },
      build: build,
      act: (bloc) async {
        bloc.add(const SearchQueryChanged('dune'));
        await Future<void>.delayed(settle);
        bloc.add(const SearchLanguageChanged('ita'));
      },
      wait: settle,
      verify: (bloc) {
        expect(bloc.state.language, 'ita');
        expect(bloc.state.status, RequestStatus.success);
        verify(() => repository.search('dune', language: 'ita')).called(1);
      },
    );

    blocTest<SearchBloc, SearchState>(
      'without a query it only remembers the language',
      build: build,
      act: (bloc) => bloc.add(const SearchLanguageChanged('eng')),
      expect: () => const [SearchState(language: 'eng')],
      verify: (_) => verifyNever(
        () => repository.search(any(), language: any(named: 'language')),
      ),
    );

    test('the language survives restarts through the preference', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final preference = SearchLanguagePreference(prefs);

      final first = build(preference);
      first.add(const SearchLanguageChanged('ita'));
      await Future<void>.delayed(settle);
      await first.close();

      final second = build(preference);
      expect(second.state.language, 'ita');
      await second.close();
    });
  });

  group('BookDetailsBloc edition', () {
    late MockLibraryRepository library;
    late MockBookSearchRepository search;
    late MockAddBookToLibrary addBook;
    late MockReadingLogRepository logs;
    late MockQuoteRepository quotes;
    const edition = BookEdition(key: 'OL9M', pageCount: 700, language: 'ita');

    setUpAll(() => registerFallbackValue(buildUserBook()));
    setUp(() {
      library = MockLibraryRepository();
      search = MockBookSearchRepository();
      addBook = MockAddBookToLibrary();
      logs = MockReadingLogRepository();
      when(() => logs.forBook(any())).thenAnswer((_) async => []);
      quotes = MockQuoteRepository();
      when(() => quotes.forBook(any())).thenAnswer((_) async => []);
      logs = MockReadingLogRepository();
      when(() => logs.forBook(any())).thenAnswer((_) async => []);
    });

    BookDetailsBloc build() => BookDetailsBloc(
          libraryRepository: library,
          searchRepository: search,
          addBook: addBook,
          readingLogs: logs,
          quotes: quotes,
        );

    blocTest<BookDetailsBloc, BookDetailsState>(
      'a preview keeps the edition until the book is added',
      build: build,
      seed: () => BookDetailsState(
        status: RequestStatus.success,
        book: buildBook(),
      ),
      act: (bloc) => bloc.add(const BookDetailsEditionSelected(edition)),
      verify: (bloc) {
        expect(bloc.state.book!.pageCount, 700);
        expect(bloc.state.book!.editionKey, 'OL9M');
        verifyNever(() => library.update(any()));
      },
    );

    blocTest<BookDetailsBloc, BookDetailsState>(
      'a saved book stores the edition',
      setUp: () => when(() => library.update(any()))
          .thenAnswer((i) async => i.positionalArguments.first as UserBook),
      build: build,
      seed: () {
        final saved = buildUserBook();
        return BookDetailsState(
          status: RequestStatus.success,
          book: saved.book,
          userBook: saved,
        );
      },
      act: (bloc) => bloc.add(const BookDetailsEditionSelected(edition)),
      verify: (bloc) {
        final sent = verify(() => library.update(captureAny())).captured.single
            as UserBook;
        expect(sent.book.pageCount, 700);
        expect(sent.book.editionKey, 'OL9M');
        expect(bloc.state.book!.pageCount, 700);
      },
    );
  });
}
