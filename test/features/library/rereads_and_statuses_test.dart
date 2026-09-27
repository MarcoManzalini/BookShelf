import 'package:bookshelf/features/library/data/mappers/user_book_mapper.dart';
import 'package:bookshelf/features/library/domain/entities/book_read.dart';
import 'package:bookshelf/features/library/domain/entities/reading_stats.dart';
import 'package:bookshelf/features/library/domain/entities/reading_status.dart';
import 'package:bookshelf/features/library/presentation/bloc/library_bloc.dart';
import 'package:bookshelf/features/library_io/data/goodreads_csv_parser.dart';
import 'package:bookshelf/features/library_io/data/library_csv_exporter.dart';
import 'package:bookshelf/features/stats/domain/entities/month_detail.dart';
import 'package:bookshelf/features/stats/domain/entities/reading_insights.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures.dart';

void main() {
  final now = DateTime(2026, 9, 27);

  group('paused and did-not-finish', () {
    test('keep the start date and the bookmark, and clear the end', () {
      final reading = buildUserBook(
        status: ReadingStatus.reading,
        currentPage: 120,
        startedAt: DateTime(2026, 9, 1),
      );
      for (final status in [ReadingStatus.paused, ReadingStatus.abandoned]) {
        final changed = reading.withStatus(status, now: now);
        expect(changed.status, status);
        expect(changed.currentPage, 120);
        expect(changed.startedAt, DateTime(2026, 9, 1));
        expect(changed.finishedAt, isNull);
        expect(changed.readCount, 0);
      }
    });

    test('pausing a book never started dates it today', () {
      final book = buildUserBook().withStatus(ReadingStatus.paused, now: now);
      expect(book.startedAt, now);
    });

    test('moving the bookmark forward resumes the book', () {
      final paused = buildUserBook(
        status: ReadingStatus.paused,
        currentPage: 120,
        startedAt: DateTime(2026, 9, 1),
      );
      expect(paused.withProgress(150, now: now).status, ReadingStatus.reading);
      // A correction backwards is not reading.
      expect(paused.withProgress(100, now: now).status, ReadingStatus.paused);
    });

    test('cannot be chosen when adding a book', () {
      expect(ReadingStatus.addable, isNot(contains(ReadingStatus.paused)));
      expect(ReadingStatus.addable, isNot(contains(ReadingStatus.abandoned)));
    });

    test('have their own library filters', () {
      final books = [
        buildUserBook(id: 'a', status: ReadingStatus.paused),
        buildUserBook(id: 'b', status: ReadingStatus.abandoned),
        buildUserBook(id: 'c', status: ReadingStatus.reading),
      ];
      final state = LibraryState(books: books, filter: LibraryFilter.abandoned);
      expect(state.visibleBooks.map((b) => b.id), ['b']);
      expect(
        state.copyWith(filter: LibraryFilter.paused).visibleBooks.single.id,
        'a',
      );
    });

    test('unknown database values fall back to want to read', () {
      expect(ReadingStatus.fromDb('paused'), ReadingStatus.paused);
      expect(ReadingStatus.fromDb('abandoned'), ReadingStatus.abandoned);
      expect(ReadingStatus.fromDb('???'), ReadingStatus.wantToRead);
    });
  });

  group('re-reads', () {
    final finished = buildUserBook(
      status: ReadingStatus.read,
      currentPage: 400,
      startedAt: DateTime(2025, 1, 1),
      finishedAt: DateTime(2025, 2, 1),
    );

    test('reading again keeps the finished read in the history', () {
      final again = finished.withReread(now: now);
      expect(again.status, ReadingStatus.reading);
      expect(again.currentPage, 0);
      expect(again.startedAt, now);
      expect(again.finishedAt, isNull);
      expect(again.pastReads, [
        BookRead(
          startedAt: DateTime(2025, 1, 1),
          finishedAt: DateTime(2025, 2, 1),
        ),
      ]);
      expect(again.readCount, 1);
      expect(again.withStatus(ReadingStatus.read, now: now).readCount, 2);
    });

    test('count once as a book but every time towards pages and the year', () {
      final twice = finished.withReread(now: DateTime(2026, 3, 1)).withStatus(
            ReadingStatus.read,
            now: DateTime(2026, 4, 1),
          );
      final lastYear =
          ReadingStats.fromBooks([twice], now: DateTime(2025, 6, 1));
      expect(lastYear.booksRead, 1);
      expect(lastYear.totalPages, 800);
      expect(lastYear.booksThisYear, 1);

      final insights =
          ReadingInsights.compute(books: [twice], logs: const [], now: now);
      expect(insights.booksReadTotal, 1);
      expect(insights.pagesReadTotal, 800);
      expect(insights.booksReadThisYear, 1);
      expect(insights.booksPerMonth[3], 1);
    });

    test('a book read twice in a month is listed once', () {
      final book = buildUserBook(
        status: ReadingStatus.read,
        finishedAt: DateTime(2026, 9, 20),
      ).copyWith(pastReads: [BookRead(finishedAt: DateTime(2026, 9, 5))]);
      final detail = MonthDetail.compute(
        books: [book],
        logs: const [],
        year: 2026,
        month: 9,
      );
      expect(detail.booksFinished, [book]);
    });

    test('undated reads count as books but not in any year', () {
      final book = buildUserBook(status: ReadingStatus.abandoned)
          .copyWith(pastReads: const [BookRead(), BookRead()]);
      final stats = ReadingStats.fromBooks([book], now: now);
      expect(stats.booksRead, 1);
      expect(stats.booksThisYear, 0);
      expect(book.readCount, 2);
    });

    test('survive the round trip through the database row', () {
      final book = finished.withReread(now: now);
      final json = UserBookMapper.toCacheJson(book);
      expect(json['past_reads'], [
        {'started_at': '2025-01-01', 'finished_at': '2025-02-01'},
      ]);
      expect(UserBookMapper.fromJson(json), book);
      expect(UserBookMapper.toUpdateJson(book)['past_reads'], hasLength(1));
      // Rows written before the column existed.
      expect(
        UserBookMapper.fromJson(json..remove('past_reads')).pastReads,
        isEmpty,
      );
    });
  });

  group('CSV', () {
    const header = 'Title,Author,Date Read,Exclusive Shelf,Bookshelves,'
        'Read Count';

    test('reads did-not-finish, paused and the read count', () {
      final rows = GoodreadsCsvParser.parse(
        [
          header,
          'Dune,Frank Herbert,2024/05/01,read,"read, classics",3',
          'Ulysses,James Joyce,,did-not-finish,did-not-finish,0',
          'Emma,Jane Austen,,on-hold,on-hold,1',
        ].join('\n'),
      ).rows;
      expect(rows[0].status, ReadingStatus.read);
      expect(rows[0].earlierReads, 2);
      expect(rows[0].shelves, ['classics']);
      expect(rows[1].status, ReadingStatus.abandoned);
      expect(rows[1].shelves, isEmpty);
      expect(rows[2].status, ReadingStatus.paused);
      expect(rows[2].earlierReads, 1);
    });

    test('exports statuses and read counts that it can read back', () {
      final books = [
        buildUserBook(id: 'a', status: ReadingStatus.abandoned),
        buildUserBook(id: 'b', status: ReadingStatus.paused),
        buildUserBook(
          id: 'c',
          status: ReadingStatus.read,
          finishedAt: DateTime(2026, 1, 1),
        ).copyWith(pastReads: const [BookRead()]),
      ];
      final rows =
          GoodreadsCsvParser.parse(LibraryCsvExporter.build(books)).rows;
      expect(rows.map((r) => r.status), [
        ReadingStatus.abandoned,
        ReadingStatus.paused,
        ReadingStatus.read,
      ]);
      expect(rows.map((r) => r.earlierReads), [0, 0, 1]);
    });
  });
}
