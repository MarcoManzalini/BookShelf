import 'package:bookshelf/features/library/domain/entities/reading_stats.dart';
import 'package:bookshelf/features/library/domain/entities/reading_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures.dart';

void main() {
  final now = DateTime(2025, 6, 15, 18, 30);
  final today = DateTime(2025, 6, 15);

  group('UserBook.withStatus', () {
    test('reading sets startedAt to today and clears finishedAt', () {
      final result = buildUserBook(finishedAt: DateTime(2024))
          .withStatus(ReadingStatus.reading, now: now);
      expect(result.status, ReadingStatus.reading);
      expect(result.startedAt, today);
      expect(result.finishedAt, isNull);
    });

    test('reading keeps an existing startedAt', () {
      final started = DateTime(2025, 1, 2);
      final result = buildUserBook(startedAt: started)
          .withStatus(ReadingStatus.reading, now: now);
      expect(result.startedAt, started);
    });

    test('read completes progress and sets both dates', () {
      final result = buildUserBook(currentPage: 12)
          .withStatus(ReadingStatus.read, now: now);
      expect(result.currentPage, 400);
      expect(result.startedAt, today);
      expect(result.finishedAt, today);
      expect(result.progress, 1);
    });

    test('leaving read clears finishedAt', () {
      final result = buildUserBook(
        status: ReadingStatus.read,
        finishedAt: today,
      ).withStatus(ReadingStatus.reading, now: now);
      expect(result.finishedAt, isNull);
    });
  });

  group('UserBook.withProgress', () {
    test('moves a want-to-read book to reading', () {
      final result = buildUserBook().withProgress(50, now: now);
      expect(result.status, ReadingStatus.reading);
      expect(result.startedAt, today);
      expect(result.progress, closeTo(0.125, 1e-9));
    });

    test('clamps to the page count and marks the book as read', () {
      final result = buildUserBook(status: ReadingStatus.reading)
          .withProgress(9999, now: now);
      expect(result.currentPage, 400);
      expect(result.status, ReadingStatus.read);
    });

    test('never goes below zero', () {
      expect(buildUserBook().withProgress(-5).currentPage, 0);
    });

    test('without a page count progress is unknown', () {
      final book = buildUserBook(book: buildBook(pageCount: null));
      expect(book.progress, isNull);
      expect(book.withProgress(30).currentPage, 30);
    });
  });

  group('UserBook.copyWith', () {
    test('can clear nullable fields explicitly', () {
      final rated = buildUserBook(rating: 4);
      expect(rated.copyWith(rating: () => null).rating, isNull);
      expect(rated.copyWith().rating, 4);
    });
  });

  group('ReadingStats', () {
    test('counts read books, pages and books finished this year', () {
      final stats = ReadingStats.fromBooks(
        [
          buildUserBook(
            id: '1',
            status: ReadingStatus.read,
            finishedAt: DateTime(2025, 2, 1),
          ),
          buildUserBook(
            id: '2',
            book: buildBook(id: 'X', pageCount: 100),
            status: ReadingStatus.read,
            finishedAt: DateTime(2024, 12, 31),
          ),
          buildUserBook(id: '3', status: ReadingStatus.reading),
          buildUserBook(id: '4'),
        ],
        now: now,
      );
      expect(stats.booksRead, 2);
      expect(stats.totalPages, 500);
      expect(stats.booksThisYear, 1);
    });

    test('is zero for an empty library', () {
      final stats = ReadingStats.fromBooks(const [], now: now);
      expect(stats.booksRead, 0);
      expect(stats.totalPages, 0);
      expect(stats.booksThisYear, 0);
    });
  });
}
