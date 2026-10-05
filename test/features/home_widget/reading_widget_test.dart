import 'dart:async';
import 'dart:ui';

import 'package:bookshelf/features/home_widget/library_widget_data.dart';
import 'package:bookshelf/features/home_widget/reading_widget_sync.dart';
import 'package:bookshelf/features/home_widget/stats_widget_data.dart';
import 'package:bookshelf/features/library/domain/entities/reading_status.dart';
import 'package:bookshelf/features/library/domain/entities/user_book.dart';
import 'package:bookshelf/features/profile/domain/entities/profile.dart';
import 'package:bookshelf/features/stats/domain/entities/reading_log.dart';
import 'package:bookshelf/l10n/gen/app_localizations_it.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';

ReadingLog log(String book, DateTime day, {int pages = 10}) =>
    ReadingLog(id: '$book$day', userBookId: book, loggedOn: day, pages: pages);

void main() {
  final l10n = AppLocalizationsIt();

  setUpAll(() => initializeDateFormatting('it'));

  test('shows the book read last, its progress and the streak', () {
    final data = ReadingWidgetData.compute(
      books: [
        buildUserBook(id: 'a', status: ReadingStatus.reading),
        buildUserBook(
          id: 'b',
          status: ReadingStatus.reading,
          currentPage: 100,
        ),
      ],
      logs: [
        log('a', DateTime(2026, 9, 25)),
        log('b', DateTime(2026, 9, 26)),
        log('b', DateTime(2026, 9, 24)),
      ],
      l10n: l10n,
      now: DateTime(2026, 9, 26),
    );
    expect(data.bookId, 'b');
    expect(data.title, 'Dune');
    expect(data.progress, 25);
    expect(data.progressLabel, '100 / 400 pagine');
    expect(data.left, '300 pagine rimaste');
    expect(data.lastReadDay, '2026-09-26');
    expect(data.streak, 3);
    expect(data.streakAlive, '3 giorni di fila');
    expect(data.streakToday, '3 giorni di fila · Oggi hai già letto');
    expect(data.streakNone, 'Inizia una serie oggi');
  });

  test('estimates the finish from the last two weeks of the book', () {
    final data = ReadingWidgetData.compute(
      books: [
        buildUserBook(
          id: 'a',
          status: ReadingStatus.reading,
          currentPage: 260,
          startedAt: DateTime(2026, 9, 1),
        ),
      ],
      logs: [
        // 140 pages in 14 days: 10 a day, 140 left → 14 days.
        log('a', DateTime(2026, 9, 26), pages: 100),
        log('a', DateTime(2026, 9, 20), pages: 40),
        log('a', DateTime(2026, 9, 1), pages: 120), // Too old to count.
        log('other', DateTime(2026, 9, 25), pages: 500),
      ],
      l10n: l10n,
      now: DateTime(2026, 9, 26),
    );
    expect(data.left, '140 pagine rimaste');
    expect(data.finishBy, 'Al tuo ritmo finisci verso il 10 ott');
    expect(data.since, 'In lettura dal 1 set');
  });

  test('no recent sessions: no finish estimate', () {
    final data = ReadingWidgetData.compute(
      books: [buildUserBook(status: ReadingStatus.reading)],
      logs: const [],
      l10n: l10n,
    );
    expect(data.finishBy, '');
    expect(data.since, '');
  });

  test('library widget: shelf counts, books and custom shelves', () {
    UserBook book(
      String id,
      ReadingStatus status,
      int day, [
      List<String> shelves = const [],
    ]) =>
        UserBook(
          id: id,
          book: buildBook(title: 'Book $id'),
          status: status,
          createdAt: DateTime(2026, 1, day),
          shelves: shelves,
        );
    final data = LibraryWidgetData.compute(
      books: [
        book('r1', ReadingStatus.reading, 1, ['Fantasy']),
        book('w1', ReadingStatus.wantToRead, 1, ['fantasy', 'Regali']),
        book('w2', ReadingStatus.wantToRead, 9),
        book('d1', ReadingStatus.read, 1, ['Fantasy']),
        book('p1', ReadingStatus.paused, 1),
      ],
      l10n: l10n,
    );
    expect(data.readingCount, 1);
    expect(data.wantCount, 2);
    expect(data.readCount, 1);
    expect(data.reading.single.subtitle, '0 / 400 pagine');
    expect(data.wantToRead.map((r) => r.id), ['w2', 'w1']);
    expect(data.shelves, 'Fantasy 3 · Regali 1');
    final map = data.toMap();
    expect(map['lib_r_0_title'], 'Book r1');
    expect(map['lib_r_1_id'], '');
    expect(map['lib_w_0_sub'], 'Frank Herbert');
  });

  test('stats widget: this year, goal, month and pace', () {
    final data = StatsWidgetData.compute(
      books: [
        buildUserBook(
          status: ReadingStatus.read,
          finishedAt: DateTime(2026, 3, 1),
        ),
      ],
      logs: [
        log('a', DateTime(2026, 9, 26), pages: 50),
        log('a', DateTime(2026, 8, 31), pages: 40),
      ],
      goal: 4,
      l10n: l10n,
      now: DateTime(2026, 9, 26),
    );
    expect(data.booksThisYear, 1);
    expect(data.goalProgress, 25);
    expect(data.pagesThisMonth, 50);
    expect(data.avgPagesPerDay, 3);
    expect(data.labels['stat_label_goal'], 'Obiettivo: 1 di 4');
    expect(data.labels['stat_label_books'], 'libro letto');
  });

  test('no book in progress', () {
    final data = ReadingWidgetData.compute(
      books: [buildUserBook(status: ReadingStatus.read)],
      logs: const [],
      l10n: l10n,
    );
    expect(data.title, isNull);
    expect(data.toMap()['has_book'], isFalse);
    expect(data.lastReadDay, '');
  });

  test('publishes on library and log changes, and empties on logout', () async {
    final library = MockLibraryRepository();
    final logs = MockReadingLogRepository();
    final profiles = MockProfileRepository();
    final bookUpdates = StreamController<List<UserBook>>.broadcast();
    final logUpdates = StreamController<void>.broadcast();
    addTearDown(bookUpdates.close);
    addTearDown(logUpdates.close);
    when(() => library.books).thenAnswer((_) => bookUpdates.stream);
    when(() => logs.changes).thenAnswer((_) => logUpdates.stream);
    when(() => logs.all(since: any(named: 'since')))
        .thenAnswer((_) async => []);
    when(profiles.getProfile)
        .thenAnswer((_) async => const Profile(id: 'u', readingGoal: 12));
    var cached = [buildUserBook(status: ReadingStatus.reading)];
    when(() => library.cachedBooks).thenAnswer((_) => cached);

    final published = <Map<String, Object>>[];
    final sync = ReadingWidgetSync(
      library,
      logs,
      profiles,
      locale: () => const Locale('it'),
      publish: (data) async => published.add(data),
    )..start();
    addTearDown(sync.dispose);

    // Nothing before sign-in.
    bookUpdates.add(cached);
    await pumpEventQueue();
    expect(published, isEmpty);

    await sync.refresh();
    expect(published.last['title'], 'Dune');
    expect(published.last['lib_reading_count'], 1);
    expect(published.last['stat_label_goal'], 'Obiettivo: 0 di 12');

    cached = [];
    bookUpdates.add(cached);
    await pumpEventQueue();
    expect(published.last['has_book'], isFalse);

    await sync.clear();
    expect(published.last['last_read_day'], '');
    expect(published.last['lib_r_0_title'], '');
    expect(published.last['stat_label_goal'], 'Nessun obiettivo annuale');
  });
}
