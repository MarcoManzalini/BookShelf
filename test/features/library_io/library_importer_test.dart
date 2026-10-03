import 'package:bloc_test/bloc_test.dart';
import 'package:bookshelf/core/errors/failure.dart';
import 'package:bookshelf/features/library/domain/entities/reading_status.dart';
import 'package:bookshelf/features/library/domain/entities/user_book.dart';
import 'package:bookshelf/features/library_io/data/open_library_reading_log.dart';
import 'package:bookshelf/features/library_io/domain/import_row.dart';
import 'package:bookshelf/features/library_io/domain/library_importer.dart';
import 'package:bookshelf/features/library_io/presentation/cubit/import_cubit.dart';
import 'package:bookshelf/features/search/domain/entities/book.dart';
import 'package:bookshelf/features/search/domain/entities/book_search_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';

class MockReadingLog extends Mock implements OpenLibraryReadingLog {}

void main() {
  late MockBookSearchRepository search;
  late MockLibraryRepository library;

  setUpAll(() {
    registerFallbackValue(buildBook());
    registerFallbackValue(buildUserBook());
    registerFallbackValue(ReadingStatus.read);
  });

  setUp(() {
    search = MockBookSearchRepository();
    library = MockLibraryRepository();
    when(() => library.findCachedByExternalId(any())).thenReturn(null);
    when(() => library.add(any(), any())).thenAnswer(
      (i) async => buildUserBook(
        id: 'ub-${(i.positionalArguments[0] as Book).externalId}',
        book: i.positionalArguments[0] as Book,
        status: i.positionalArguments[1] as ReadingStatus,
      ),
    );
    when(() => library.update(any()))
        .thenAnswer((i) async => i.positionalArguments.first as UserBook);
  });

  LibraryImporter build() => LibraryImporter(
        search,
        library,
        concurrency: 1,
        pause: Duration.zero,
      );

  Future<ImportProgress> runAll(
    List<ImportRow> rows, {
    bool Function()? cancelled,
  }) =>
      build().run(rows, isCancelled: cancelled).last;

  const dune = ImportRow(
    title: 'Dune (Dune Chronicles, #1)',
    author: 'Frank Herbert',
    isbn13: '9780441172719',
    status: ReadingStatus.read,
    rating: 5,
    notes: 'Loved it',
    shelves: ['Sci-fi'],
  );

  BookSearchPage page(List<Book> books) =>
      BookSearchPage(books: books, page: 1, hasMore: false);

  group('matching', () {
    test('an ISBN match wins and no text search is made', () async {
      when(() => search.findByIsbn('9780441172719'))
          .thenAnswer((_) async => buildBook(id: 'OL1W'));

      final progress = await runAll([dune]);

      expect(progress.imported, 1);
      verifyNever(() => search.search(any(), language: any(named: 'language')));
    });

    test('an Open Library work id is matched directly', () async {
      when(() => search.findByWorkId('OL9W'))
          .thenAnswer((_) async => buildBook(id: 'OL9W'));

      final progress = await runAll([
        const ImportRow(
          title: 'Dune',
          workId: 'OL9W',
          status: ReadingStatus.wantToRead,
        ),
      ]);

      expect(progress.imported, 1);
      verifyNever(() => search.search(any(), language: any(named: 'language')));
      verifyNever(() => search.findByIsbn(any()));
    });

    test('without an ISBN it searches title and author', () async {
      when(() => search.search('Dune Frank Herbert'))
          .thenAnswer((_) async => page([buildBook(id: 'OL1W')]));

      final progress = await runAll([
        const ImportRow(
          title: 'Dune',
          author: 'Frank Herbert',
          status: ReadingStatus.wantToRead,
        ),
      ]);
      expect(progress.imported, 1);
    });

    test('falls back to search when the ISBN is unknown', () async {
      when(() => search.findByIsbn(any())).thenAnswer((_) async => null);
      when(() => search.search(any()))
          .thenAnswer((_) async => page([buildBook(id: 'OL1W')]));

      expect((await runAll([dune])).imported, 1);
    });

    test('a doubtful match is not imported', () async {
      when(() => search.search(any())).thenAnswer(
        (_) async => page([buildBook(id: 'OL9W', title: 'Dune Messiah')]),
      );

      final progress = await runAll([
        const ImportRow(
          title: 'Emma',
          author: 'Jane Austen',
          status: ReadingStatus.read,
        ),
      ]);

      expect(progress.imported, 0);
      expect(progress.notFound.single.title, 'Emma');
      verifyNever(() => library.add(any(), any()));
    });

    test('pickBestMatch ignores series marks and punctuation', () {
      final book = buildBook(title: 'Dune');
      const row = ImportRow(
        title: 'Dune (Dune Chronicles, #1)',
        author: 'Herbert, Frank',
        status: ReadingStatus.read,
      );
      expect(LibraryImporter.pickBestMatch([book], row), book);
    });

    test('pickBestMatch rejects the same title by another author', () {
      final other = buildBook(title: 'Dune').copyWith();
      const row = ImportRow(
        title: 'Dune',
        author: 'Someone Else',
        status: ReadingStatus.read,
      );
      expect(LibraryImporter.pickBestMatch([other], row), isNull);
    });

    test('pickBestMatch does not confuse a title with a longer one', () {
      final messiah = buildBook(id: 'OL2W', title: 'Dune Messiah');
      const row = ImportRow(title: 'Dune', status: ReadingStatus.read);
      // "Dune Messiah" starts with "dune " so it could match a bare "Dune":
      // that is accepted only when nothing better exists, and never the
      // other way round.
      expect(LibraryImporter.pickBestMatch([messiah], row), messiah);
      expect(
        LibraryImporter.pickBestMatch(
          [messiah, buildBook(id: 'OL1W', title: 'Dune')],
          row,
        )?.externalId,
        'OL2W',
        reason: 'first acceptable candidate wins; search order decides',
      );
    });
  });

  group('saving', () {
    setUp(() {
      when(() => search.findByIsbn(any()))
          .thenAnswer((_) async => buildBook(id: 'OL1W'));
    });

    test('applies rating, notes, shelves and dates from the file', () async {
      final progress = await runAll([
        ImportRow(
          title: dune.title,
          isbn13: dune.isbn13,
          status: ReadingStatus.read,
          rating: 4,
          notes: 'Great',
          shelves: const ['Sci-fi', 'sci-fi', 'Regali'],
          finishedOn: DateTime(2021, 3, 15),
          addedOn: DateTime(2020, 12, 1),
        ),
      ]);

      expect(progress.imported, 1);
      final saved = verify(() => library.update(captureAny())).captured.single
          as UserBook;
      expect(saved.rating, 4);
      expect(saved.notes, 'Great');
      expect(saved.shelves, ['Sci-fi', 'Regali']);
      expect(saved.finishedAt, DateTime(2021, 3, 15));
      expect(saved.startedAt, DateTime(2020, 12, 1));
    });

    test('a date added after the finish date does not start after the end',
        () async {
      await runAll([
        ImportRow(
          title: 'Dune',
          isbn13: dune.isbn13,
          status: ReadingStatus.read,
          finishedOn: DateTime(2020, 1, 1),
          addedOn: DateTime(2021, 1, 1),
        ),
      ]);
      final saved = verify(() => library.update(captureAny())).captured.single
          as UserBook;
      expect(saved.startedAt, DateTime(2020, 1, 1));
    });

    test('a want-to-read book with nothing else needs no second request',
        () async {
      await runAll([
        const ImportRow(
          title: 'Dune',
          isbn13: '9780441172719',
          status: ReadingStatus.wantToRead,
        ),
      ]);
      verifyNever(() => library.update(any()));
    });

    test('fills the page count from the file when Open Library has none',
        () async {
      when(() => search.findByIsbn(any())).thenAnswer(
        (_) async => buildBook(id: 'OL1W', pageCount: null),
      );
      await runAll([
        const ImportRow(
          title: 'Dune',
          isbn13: '9780441172719',
          status: ReadingStatus.wantToRead,
          pages: 321,
        ),
      ]);
      final saved = verify(() => library.update(captureAny())).captured.single
          as UserBook;
      expect(saved.book.pageCount, 321);
    });

    test('books already in the library are skipped and counted', () async {
      when(() => library.findCachedByExternalId('OL1W'))
          .thenReturn(buildUserBook());

      final progress = await runAll([dune]);

      expect(progress.duplicates, 1);
      expect(progress.imported, 0);
      verifyNever(() => library.add(any(), any()));
    });

    test('a failing extras update does not undo the import', () async {
      when(() => library.update(any()))
          .thenThrow(const Failure(FailureCode.server));
      final progress = await runAll([dune]);
      expect(progress.imported, 1);
      expect(progress.failed, isEmpty);
    });

    test('a book that cannot be saved is reported and the rest go on',
        () async {
      var calls = 0;
      when(() => library.add(any(), any())).thenAnswer((i) async {
        if (calls++ == 0) throw const Failure(FailureCode.server);
        return buildUserBook(book: i.positionalArguments[0] as Book);
      });
      when(() => search.findByIsbn(any())).thenAnswer(
        (i) async => buildBook(id: 'OL${i.positionalArguments.first}W'),
      );

      final progress = await runAll([
        const ImportRow(
          title: 'A',
          isbn13: '9780441172719',
          status: ReadingStatus.wantToRead,
        ),
        const ImportRow(
          title: 'B',
          isbn13: '9780804429573',
          status: ReadingStatus.wantToRead,
        ),
      ]);

      expect(progress.failed.map((r) => r.title), ['A']);
      expect(progress.imported, 1);
      expect(progress.processed, 2);
    });
  });

  group('interruptions', () {
    test('losing the connection stops the import', () async {
      when(() => search.findByIsbn(any()))
          .thenThrow(const Failure(FailureCode.network));

      final progress = await runAll([
        dune,
        dune,
      ]);

      expect(progress.aborted, const Failure(FailureCode.network));
      expect(progress.processed, 0, reason: 'nothing was counted as failed');
    });

    test('cancelling stops after the rows already handled', () async {
      when(() => search.findByIsbn(any()))
          .thenAnswer((_) async => buildBook(id: 'OL1W'));
      var handled = 0;
      when(() => library.add(any(), any())).thenAnswer((i) async {
        handled++;
        return buildUserBook(book: i.positionalArguments[0] as Book);
      });

      final progress = await runAll(
        List.filled(5, dune),
        cancelled: () => handled >= 2,
      );

      expect(progress.cancelled, isTrue);
      expect(handled, 2);
      expect(progress.processed, 2);
    });

    test('progress is reported row by row', () async {
      when(() => search.findByIsbn(any()))
          .thenAnswer((_) async => buildBook(id: 'OL1W'));
      final seen = await build().run([dune, dune, dune]).toList();
      expect(seen.map((p) => p.processed), [1, 2, 3]);
      expect(seen.last.fraction, 1);
    });
  });

  group('ImportCubit', () {
    const csv = 'Title,Exclusive Shelf\nDune,read\nEmma,to-read\n';

    ImportCubit cubit() => ImportCubit(build(), MockReadingLog());

    blocTest<ImportCubit, ImportState>(
      'reading a file shows what it holds',
      build: cubit,
      act: (c) => c.loadFile('lib.csv', csv),
      verify: (c) {
        expect(c.state.step, ImportStep.ready);
        expect(c.state.rows, hasLength(2));
        expect(c.state.fileName, 'lib.csv');
      },
    );

    blocTest<ImportCubit, ImportState>(
      'an Open Library reading log is fetched and shown',
      build: () {
        final log = MockReadingLog();
        when(() => log.fetch('reader')).thenAnswer(
          (_) async => const [
            ImportRow(
              title: 'Dune',
              workId: 'OL1W',
              status: ReadingStatus.read,
            ),
          ],
        );
        return ImportCubit(build(), log);
      },
      act: (c) => c.loadOpenLibrary('reader'),
      expect: () => [
        const ImportState(
          step: ImportStep.fetching,
          fileName: 'Open Library · reader',
        ),
        const ImportState(
          step: ImportStep.ready,
          fileName: 'Open Library · reader',
          rows: [
            ImportRow(
              title: 'Dune',
              workId: 'OL1W',
              status: ReadingStatus.read,
            ),
          ],
        ),
      ],
    );

    blocTest<ImportCubit, ImportState>(
      'a private reading log is explained',
      build: () {
        final log = MockReadingLog();
        when(() => log.fetch(any())).thenThrow(
          const ReadingLogException(ReadingLogError.private),
        );
        return ImportCubit(build(), log);
      },
      act: (c) => c.loadOpenLibrary('reader'),
      verify: (c) {
        expect(c.state.step, ImportStep.sourceFailed);
        expect(c.state.sourceError, ReadingLogError.private);
      },
    );

    blocTest<ImportCubit, ImportState>(
      'a file that is not a book list is rejected',
      build: cubit,
      act: (c) => c.loadFile('x.csv', 'a,b\n1,2'),
      verify: (c) => expect(c.state.step, ImportStep.invalidFile),
    );

    blocTest<ImportCubit, ImportState>(
      'a header-only file is rejected',
      build: cubit,
      act: (c) => c.loadFile('x.csv', 'Title,Author\n'),
      verify: (c) => expect(c.state.step, ImportStep.invalidFile),
    );

    blocTest<ImportCubit, ImportState>(
      'runs the import and ends in the done step',
      setUp: () {
        when(() => search.findByIsbn(any())).thenAnswer((_) async => null);
        when(() => search.search(any())).thenAnswer(
          (i) async => page([
            buildBook(
              id: 'OL-${i.positionalArguments.first}',
              title: (i.positionalArguments.first as String).split(' ').first,
            ),
          ]),
        );
      },
      build: cubit,
      act: (c) async {
        c.loadFile('lib.csv', csv);
        await c.start();
      },
      verify: (c) {
        expect(c.state.step, ImportStep.done);
        expect(c.state.progress!.imported, 2);
        expect(c.state.progress!.total, 2);
      },
    );

    blocTest<ImportCubit, ImportState>(
      'reset returns to the start',
      build: cubit,
      act: (c) {
        c.loadFile('lib.csv', csv);
        c.reset();
      },
      expect: () => [
        isA<ImportState>().having((s) => s.step, 'step', ImportStep.ready),
        const ImportState(),
      ],
    );
  });
}
