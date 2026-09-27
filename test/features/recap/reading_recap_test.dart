import 'package:bookshelf/features/library/domain/entities/book_format.dart';
import 'package:bookshelf/features/library/domain/entities/book_read.dart';
import 'package:bookshelf/features/library/domain/entities/book_vibe.dart';
import 'package:bookshelf/features/library/domain/entities/reading_status.dart';
import 'package:bookshelf/features/recap/domain/reading_recap.dart';
import 'package:bookshelf/features/search/domain/entities/book.dart';
import 'package:bookshelf/features/stats/domain/entities/reading_log.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures.dart';

ReadingLog log(DateTime day, int pages, {int? minutes}) => ReadingLog(
      id: '$day$pages',
      userBookId: 'x',
      loggedOn: day,
      pages: pages,
      minutes: minutes,
    );

void main() {
  final dune = buildUserBook(
    id: 'dune',
    book: const Book(
      externalId: 'OL1W',
      title: 'Dune',
      pageCount: 600,
      subjects: ['Science fiction'],
    ),
    status: ReadingStatus.read,
    rating: 5,
    startedAt: DateTime(2026, 3, 1),
    finishedAt: DateTime(2026, 3, 20),
  ).copyWith(moods: [BookMood.adventurous]);
  final quick = buildUserBook(
    id: 'quick',
    book: const Book(
      externalId: 'OL2W',
      title: 'Breve',
      pageCount: 120,
      subjects: ['Science fiction'],
    ),
    status: ReadingStatus.read,
    rating: 3,
    startedAt: DateTime(2026, 9, 5),
    finishedAt: DateTime(2026, 9, 6),
  ).copyWith(
    // Read before, and again this year.
    pastReads: [BookRead(finishedAt: DateTime(2020, 1, 1))],
    format: BookFormat.ebook,
  );
  final lastYear = buildUserBook(
    id: 'old',
    status: ReadingStatus.read,
    finishedAt: DateTime(2025, 12, 31),
  );

  test('a year: books, highlights and taste', () {
    final recap = ReadingRecap.compute(
      period: const RecapPeriod.year(2026),
      books: [
        dune,
        quick,
        lastYear,
        buildUserBook(
          id: 'march',
          status: ReadingStatus.read,
          finishedAt: DateTime(2026, 3, 2),
        ),
      ],
      logs: const [],
    );
    expect(recap.finished.map((r) => r.book.id), ['quick', 'dune', 'march']);
    // No log: the pages of the finished books.
    expect(recap.pagesRead, 1120);
    expect(recap.topRated!.book.id, 'dune');
    expect(recap.longest!.book.id, 'dune');
    expect(recap.fastest!.book.id, 'quick');
    expect(recap.fastest!.days, 2);
    expect(recap.topSubject, 'Science fiction');
    expect(recap.topMood, BookMood.adventurous);
    expect(recap.formats, {BookFormat.ebook: 1, BookFormat.paper: 2});
    expect(recap.rereads, 1);
    expect(recap.busiestMonth, 3);
  });

  test('a month: activity from the log', () {
    final recap = ReadingRecap.compute(
      period: const RecapPeriod.month(2026, 9),
      books: [dune, quick],
      logs: [
        log(DateTime(2026, 9, 1), 20, minutes: 30),
        log(DateTime(2026, 9, 2), 50),
        log(DateTime(2026, 9, 3), 10),
        log(DateTime(2026, 9, 10), 5),
        log(DateTime(2026, 8, 31), 99), // outside the month
      ],
    );
    expect(recap.finished.single.book.id, 'quick');
    expect(recap.pagesRead, 85);
    expect(recap.minutesRead, 30);
    expect(recap.activeDays, 4);
    expect(recap.longestStreak, 3);
    expect(recap.bestDay, DateTime(2026, 9, 2));
    expect(recap.bestDayPages, 50);
    expect(recap.busiestMonth, isNull);
    expect(recap.isEmpty, isFalse);
  });

  test('nothing in the period', () {
    final recap = ReadingRecap.compute(
      period: const RecapPeriod.month(2026, 1),
      books: [dune],
      logs: const [],
    );
    expect(recap.isEmpty, isTrue);
  });

  test('periods', () {
    const december = RecapPeriod.month(2026, 12);
    expect(december.end, DateTime(2027));
    expect(december.contains(DateTime(2026, 12, 31)), isTrue);
    expect(december.contains(DateTime(2027)), isFalse);
  });
}
