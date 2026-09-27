import 'dart:async';
import 'dart:ui';

import 'package:bookshelf/features/home_widget/reading_widget_sync.dart';
import 'package:bookshelf/features/library/domain/entities/reading_status.dart';
import 'package:bookshelf/features/library/domain/entities/user_book.dart';
import 'package:bookshelf/features/stats/domain/entities/reading_log.dart';
import 'package:bookshelf/l10n/gen/app_localizations_it.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';

ReadingLog log(String book, DateTime day) =>
    ReadingLog(id: '$book$day', userBookId: book, loggedOn: day, pages: 10);

void main() {
  final l10n = AppLocalizationsIt();

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
    );
    expect(data.title, 'Dune');
    expect(data.progress, 25);
    expect(data.progressLabel, '100 / 400 pagine');
    expect(data.lastReadDay, '2026-09-26');
    expect(data.streakAlive, '3 giorni di fila');
    expect(data.streakToday, '3 giorni di fila · Oggi hai già letto');
    expect(data.streakNone, 'Inizia una serie oggi');
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
    final bookUpdates = StreamController<List<UserBook>>.broadcast();
    final logUpdates = StreamController<void>.broadcast();
    addTearDown(bookUpdates.close);
    addTearDown(logUpdates.close);
    when(() => library.books).thenAnswer((_) => bookUpdates.stream);
    when(() => logs.changes).thenAnswer((_) => logUpdates.stream);
    when(() => logs.all(since: any(named: 'since')))
        .thenAnswer((_) async => []);
    var cached = [buildUserBook(status: ReadingStatus.reading)];
    when(() => library.cachedBooks).thenAnswer((_) => cached);

    final published = <Map<String, Object>>[];
    final sync = ReadingWidgetSync(
      library,
      logs,
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

    cached = [];
    bookUpdates.add(cached);
    await pumpEventQueue();
    expect(published.last['has_book'], isFalse);

    await sync.clear();
    expect(published.last['last_read_day'], '');
  });
}
