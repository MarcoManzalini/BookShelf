import 'package:bookshelf/features/library/domain/entities/reading_status.dart';
import 'package:bookshelf/features/stats/domain/entities/reading_insights.dart';
import 'package:bookshelf/features/stats/domain/entities/reading_log.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures.dart';

void main() {
  final now = DateTime(2026, 9, 20, 15, 30);

  ReadingLog log(int daysAgo, {int pages = 10, int? minutes}) => ReadingLog(
        id: 'l$daysAgo-$pages',
        userBookId: 'ub-1',
        loggedOn: DateTime(2026, 9, 20 - daysAgo),
        pages: pages,
        minutes: minutes,
      );

  ReadingInsights compute({
    List<ReadingLog> logs = const [],
    int? goal,
    List<dynamic>? books,
  }) =>
      ReadingInsights.compute(
        books: (books ?? const []).cast(),
        logs: logs,
        goal: goal,
        now: now,
      );

  group('books', () {
    final read = [
      buildUserBook(
        id: 'a',
        status: ReadingStatus.read,
        rating: 5,
        finishedAt: DateTime(2026, 1, 10),
      ),
      buildUserBook(
        id: 'b',
        book: buildBook(id: 'OL2W', pageCount: 200),
        status: ReadingStatus.read,
        rating: 3,
        finishedAt: DateTime(2026, 1, 25),
      ),
      buildUserBook(
        id: 'c',
        book: buildBook(id: 'OL3W', pageCount: 100),
        status: ReadingStatus.read,
        finishedAt: DateTime(2025, 12, 31),
      ),
      buildUserBook(id: 'd', status: ReadingStatus.reading, rating: 4),
    ];

    test('counts books, pages and this year per month', () {
      final i = compute(books: read);
      expect(i.booksReadTotal, 3);
      expect(i.pagesReadTotal, 400 + 200 + 100);
      expect(i.booksReadThisYear, 2, reason: 'the 2025 one is last year');
      expect(i.booksPerMonth[0], 2);
      expect(i.booksPerMonth.sum, 2);
    });

    test('averages the ratings the reader gave, unread ones included', () {
      expect(compute(books: read).avgRating, 4);
      expect(compute().avgRating, isNull);
    });

    test('goal progress is clamped and absent without a goal', () {
      expect(compute(books: read, goal: 4).goalProgress, 0.5);
      expect(compute(books: read, goal: 1).goalProgress, 1.0);
      expect(compute(books: read).goalProgress, isNull);
    });
  });

  group('streak', () {
    test('counts consecutive days ending today', () {
      final i = compute(logs: [log(0), log(1), log(2), log(4)]);
      expect(i.streakDays, 3);
    });

    test('is still alive when the reader has not read yet today', () {
      final i = compute(logs: [log(1), log(2)]);
      expect(i.streakDays, 2);
    });

    test('is broken after a missed day', () {
      expect(compute(logs: [log(2), log(3)]).streakDays, 0);
    });

    test('several sessions on one day count once', () {
      expect(compute(logs: [log(0), log(0, pages: 5), log(1)]).streakDays, 2);
    });

    test('a time-only session counts as reading', () {
      expect(compute(logs: [log(0, pages: 0, minutes: 20)]).streakDays, 1);
    });

    test('an empty session does not count', () {
      expect(compute(logs: [log(0, pages: 0)]).streakDays, 0);
    });
  });

  group('pace', () {
    test('lists the last 14 days oldest first, ending today', () {
      final i = compute(logs: [log(0, pages: 30), log(13, pages: 7), log(14)]);
      expect(i.pagesLast14Days, hasLength(14));
      expect(i.pagesLast14Days.last, 30);
      expect(i.pagesLast14Days.first, 7);
      expect(i.pagesLast14Days.sum, 37, reason: 'day 14 is out of range');
    });

    test('averages the pages over 30 days', () {
      final i = compute(logs: [log(0, pages: 60), log(10, pages: 60)]);
      expect(i.avgPagesPerDay, 4);
    });

    test('sums the minutes of every session', () {
      final i = compute(
        logs: [log(0, minutes: 30), log(3, minutes: 45), log(4)],
      );
      expect(i.totalMinutes, 75);
    });
  });

  group('top subjects', () {
    test('ranks subjects across the library, merging spellings', () {
      Object book(String id, List<String> subjects) => buildUserBook(
            id: id,
            book: buildBook(id: 'OL${id}W').copyWith(subjects: subjects),
          );
      final i = compute(
        books: [
          book('a', ['Fantasy', 'Adventure']),
          book('b', ['fantasy']),
          book('c', ['Adventure', 'Fantasy', 'Poetry']),
        ],
      );
      expect(i.topSubjects.map((e) => '${e.key}:${e.value}'), [
        'Fantasy:3',
        'Adventure:2',
        'Poetry:1',
      ]);
    });

    test('keeps only the top five', () {
      final many = buildUserBook(
        book:
            buildBook().copyWith(subjects: [for (var i = 0; i < 9; i++) 's$i']),
      );
      expect(compute(books: [many]).topSubjects, hasLength(5));
    });
  });
}

extension on Iterable<int> {
  int get sum => fold(0, (a, b) => a + b);
}
