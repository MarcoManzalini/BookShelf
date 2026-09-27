import 'package:bookshelf/core/utils/minutes_text.dart';
import 'package:bookshelf/features/library/data/mappers/user_book_mapper.dart';
import 'package:bookshelf/features/library/domain/entities/book_format.dart';
import 'package:bookshelf/features/library/domain/entities/book_loan.dart';
import 'package:bookshelf/features/library/domain/entities/book_series.dart';
import 'package:bookshelf/features/library/domain/entities/book_vibe.dart';
import 'package:bookshelf/features/library/domain/entities/reading_stats.dart';
import 'package:bookshelf/features/library/domain/entities/reading_status.dart';
import 'package:bookshelf/features/library/domain/entities/series_catalog.dart';
import 'package:bookshelf/features/library/presentation/bloc/library_bloc.dart';
import 'package:bookshelf/features/search/domain/entities/book_edition.dart';
import 'package:bookshelf/features/library/presentation/widgets/book_extras_ui.dart';
import 'package:bookshelf/l10n/gen/app_localizations_it.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures.dart';

void main() {
  final l10n = AppLocalizationsIt();

  group('audiobooks', () {
    final audio = buildUserBook(status: ReadingStatus.reading)
        .copyWith(format: BookFormat.audio, durationMinutes: () => 600);

    test('progress is measured in minutes', () {
      expect(audio.progressTotal, 600);
      expect(audio.withProgress(150).progress, 0.25);
      expect(audio.withProgress(150).progressLabel(l10n), '2 h 30 min di 10 h');
      expect(audio.withProgress(9999).status, ReadingStatus.read);
      expect(
        audio.withStatus(ReadingStatus.read).currentPage,
        600,
        reason: 'finishing moves the bookmark to the last minute',
      );
    });

    test('do not add pages to the statistics', () {
      final done = audio.withStatus(ReadingStatus.read);
      final stats = ReadingStats.fromBooks([done]);
      expect(stats.booksRead, 1);
      expect(stats.totalPages, 0);
    });

    test('minutes are typed as h:mm or plain minutes', () {
      expect(MinutesText.parse('11:30'), 690);
      expect(MinutesText.parse('1.05'), 65);
      expect(MinutesText.parse('2h15'), 135);
      expect(MinutesText.parse('90'), 90);
      expect(MinutesText.parse('1:75'), isNull);
      expect(MinutesText.parse('abc'), isNull);
      expect(MinutesText.edit(65), '1:05');
      expect(MinutesText.format(l10n, 45), '45 min');
      expect(MinutesText.format(l10n, 120), '2 h');
    });
  });

  group('series', () {
    test('labels and the next volume', () {
      const series = BookSeries(name: 'Dune', index: 2, total: 6);
      expect(series.indexLabel, '2');
      expect(series.nextIndex(), 3);
      expect(const BookSeries(name: 'X', index: 2.5).indexLabel, '2.5');
      expect(const BookSeries(name: 'X', index: 2.5).nextIndex(), 3);
      expect(const BookSeries(name: 'X', index: 6, total: 6).nextIndex(), null);
      expect(series.sameSagaAs(const BookSeries(name: ' dune ')), isTrue);
    });

    test('one book can hold several volumes (1Q84: 1-2 and 3)', () {
      const first = BookSeries(name: '1Q84', index: 1, indexEnd: 2, total: 3);
      expect(first.isRange, isTrue);
      expect(first.indexLabel, '1–2');
      expect(first.covers(2), isTrue);
      expect(first.covers(3), isFalse);
      expect(first.nextIndex(), 3);
      const last = BookSeries(name: '1Q84', index: 3);
      expect(last.nextIndex(sagaTotal: 3), isNull);
      // An end equal to the start is just one volume.
      expect(
        const BookSeries(name: 'X', index: 2, indexEnd: 2).isRange,
        isFalse,
      );
    });

    test('the catalog groups the library by saga', () {
      final books = [
        buildUserBook(id: 'b').copyWith(
          series: () => const BookSeries(name: '1q84', index: 3),
        ),
        buildUserBook(id: 'a').copyWith(
          series: () =>
              const BookSeries(name: '1Q84', index: 1, indexEnd: 2, total: 3),
        ),
        buildUserBook(id: 'c').copyWith(
          series: () => const BookSeries(name: 'Dune', index: 1),
        ),
        buildUserBook(id: 'd'),
      ];
      final sagas = SeriesCatalog.of(books);
      expect(sagas.map((s) => s.name), ['1q84', 'Dune']);
      final q84 = sagas.first;
      expect(q84.books.map((b) => b.id), ['a', 'b']);
      expect(q84.total, 3);
      expect(q84.nextFreeVolume, 4);
      expect(q84.bookWith(2)!.id, 'a');
      expect(q84.bookWith(3)!.id, 'b');
      expect(SeriesCatalog.find(books, 'DUNE')!.nextFreeVolume, 2);
    });
  });

  group('loans', () {
    test('overdue only after the due day', () {
      final loan = BookLoan(
        kind: LoanKind.borrowed,
        person: 'Biblioteca',
        since: DateTime(2026, 9, 1),
        due: DateTime(2026, 9, 27),
      );
      expect(loan.isOverdue(DateTime(2026, 9, 27, 23)), isFalse);
      expect(loan.isOverdue(DateTime(2026, 9, 28)), isTrue);
    });
  });

  test('every new field survives the database row', () {
    final book = buildUserBook(status: ReadingStatus.reading).copyWith(
      format: BookFormat.audio,
      durationMinutes: () => 690,
      series: () =>
          const BookSeries(name: 'Dune', index: 1.5, indexEnd: 2, total: 6),
      moods: [BookMood.dark, BookMood.adventurous],
      pace: () => ReadingPace.slow,
      loan: () => BookLoan(
        kind: LoanKind.lent,
        person: 'Marco',
        since: DateTime(2026, 9, 1),
        due: DateTime(2026, 10, 1),
      ),
    );
    final json = UserBookMapper.toCacheJson(book);
    expect(json['format'], 'audio');
    expect(json['series_index'], 1.5);
    expect(json['series_index_end'], 2);
    expect(json['moods'], ['dark', 'adventurous']);
    expect(json['loan_due'], '2026-10-01');
    expect(UserBookMapper.fromJson(json), book);

    final update = UserBookMapper.toUpdateJson(book.copyWith(loan: () => null));
    expect(update['loan_kind'], isNull);
    expect(update['loan_person'], isNull);

    // Rows written before the columns existed.
    final old = UserBookMapper.fromJson(
      UserBookMapper.toCacheJson(buildUserBook())
        ..removeWhere(
          (k, _) =>
              k.startsWith('loan') ||
              k.startsWith('series') ||
              ['format', 'moods', 'pace', 'duration_minutes'].contains(k),
        ),
    );
    expect(old.format, BookFormat.paper);
    expect(old.series, isNull);
    expect(old.moods, isEmpty);
    expect(old.loan, isNull);
  });

  test('unknown moods from a newer app are dropped', () {
    expect(BookMood.fromDb(['dark', 'cosy']), [BookMood.dark]);
    expect(ReadingPace.fromDb('warp'), isNull);
    expect(BookFormat.fromDb(null), BookFormat.paper);
  });

  test('library filters by mood, pace and loans', () {
    final books = [
      buildUserBook(id: 'a').copyWith(
        moods: [BookMood.dark],
        pace: () => ReadingPace.fast,
      ),
      buildUserBook(id: 'b').copyWith(moods: [BookMood.funny]),
      buildUserBook(id: 'c').copyWith(
        loan: () => BookLoan(
          kind: LoanKind.lent,
          person: 'Anna',
          since: DateTime(2026),
        ),
      ),
    ];
    final state = LibraryState(books: books);
    expect(state.hasLoans, isTrue);
    expect(
      state.copyWith(moodFilter: () => BookMood.dark).visibleBooks.single.id,
      'a',
    );
    expect(
      state.copyWith(paceFilter: () => ReadingPace.fast).visibleBooks.single.id,
      'a',
    );
    expect(state.copyWith(onLoanOnly: true).visibleBooks.single.id, 'c');
    expect(state.copyWith(onLoanOnly: true).hasActiveFilter, isTrue);
  });

  group('changing edition', () {
    const shorter = BookEdition(key: 'OL1M', pageCount: 722);

    test('a finished book stays on the last page of the new edition', () {
      final read = buildUserBook(status: ReadingStatus.read, currentPage: 400)
          .copyWith(book: buildBook(pageCount: 925), currentPage: 925);
      final changed = read.withEdition(shorter);
      expect(changed.currentPage, 722);
      expect(changed.progressLabel(l10n), '722 / 722 pagine');
    });

    test('a bookmark never ends up past the end', () {
      final reading = buildUserBook(
        status: ReadingStatus.reading,
        currentPage: 800,
      ).copyWith(book: buildBook(pageCount: 925));
      expect(reading.withEdition(shorter).currentPage, 722);
      final early = reading.copyWith(currentPage: 100);
      expect(early.withEdition(shorter).currentPage, 100);
    });

    test('books saved past the end show the total, not more', () {
      final broken = buildUserBook(status: ReadingStatus.read)
          .copyWith(book: buildBook(pageCount: 722), currentPage: 925);
      expect(broken.progressLabel(l10n), '722 / 722 pagine');
    });
  });
}
