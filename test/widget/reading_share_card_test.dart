import 'dart:io';

import 'package:bookshelf/features/book_details/presentation/widgets/reading_share_card.dart';
import 'package:bookshelf/features/book_details/presentation/widgets/share_cards/share_card_parts.dart';
import 'package:bookshelf/features/stats/domain/entities/reading_insights.dart';
import 'package:bookshelf/features/stats/domain/entities/reading_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

/// A 1x1 transparent PNG.
final _pixel = Uint8List.fromList(const [
  0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00, 0x00, 0x0d, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1f, 0x15, 0xc4, 0x89, 0x00, 0x00, 0x00,
  0x0d, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9c, 0x63, 0xf8, 0xff, 0xff, 0x3f,
  0x00, 0x05, 0xfe, 0x02, 0xfe, 0xa7, 0x35, 0x81, 0x84, 0x00, 0x00, 0x00,
  0x00, 0x49, 0x45, 0x4e, 0x44, 0xae, 0x42, 0x60, 0x82,
]);

void main() {
  // The cards are laid out for the app font; the test default is far wider.
  setUpAll(() async {
    final loader = FontLoader('PlusJakartaSans')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/PlusJakartaSans.ttf').readAsBytesSync(),
          ),
        ),
      );
    await loader.load();
  });

  final day = DateTime(2026, 9, 20);

  ReadingShareData session({
    int pages = 47,
    int? minutes = 52,
    int? endPage = 233,
    int? totalPages = 688,
    int? streak = 5,
  }) {
    return ReadingShareData(
      title: 'Moby Dick',
      author: 'Herman Melville',
      day: day,
      pages: pages,
      minutes: minutes,
      endPage: endPage,
      totalPages: totalPages,
      streak: streak,
    );
  }

  group('ReadingShareData', () {
    test('pace is pages per hour', () {
      expect(session(pages: 30, minutes: 45).pace, 40);
    });

    test('no pace without minutes or pages', () {
      expect(session(minutes: null).pace, isNull);
      expect(session(pages: 0).pace, isNull);
    });

    test('a session starts where it ended minus its pages', () {
      expect(session(pages: 30, endPage: 100).startPage, 70);
      expect(session(endPage: null).startPage, isNull);
    });

    test('progress before and after the session', () {
      final data = session(pages: 100, endPage: 200, totalPages: 400);
      expect(data.progressBefore, 0.25);
      expect(data.progress, 0.5);
      expect(session(totalPages: null).progress, isNull);
    });

    test('a time-only session is about minutes', () {
      final data = session(pages: 0, minutes: 20);
      expect(data.heroIsMinutes, isTrue);
      expect(data.heroValue, 20);
      expect(session().heroValue, 47);
    });

    test('an unknown or zero streak is left out', () {
      expect(session(streak: null).streakDays, isNull);
      expect(session(streak: 0).streakDays, isNull);
      expect(session().withStreak(3).streakDays, 3);
    });

    test('knows whether it happened today', () {
      expect(session().isOn(DateTime(2026, 9, 20, 23, 59)), isTrue);
      expect(session().isOn(DateTime(2026, 9, 21)), isFalse);
    });
  });

  test('duration reads as minutes, then hours', () {
    expect(durationParts(45, 'min'), (value: '45', unit: 'min'));
    expect(durationParts(65, 'min'), (value: '1h05', unit: null));
    expect(durationParts(120, 'min'), (value: '2h00', unit: null));
  });

  group('streakEndingOn', () {
    ReadingLog log(DateTime on, {int pages = 10}) => ReadingLog(
          id: '${on.millisecondsSinceEpoch}',
          userBookId: 'b',
          loggedOn: on,
          pages: pages,
        );

    test('counts the days in a row up to the session day', () {
      final logs = [
        log(DateTime(2026, 9, 20)),
        log(DateTime(2026, 9, 19)),
        log(DateTime(2026, 9, 18)),
        log(DateTime(2026, 9, 15)),
        // Later days do not count for an earlier session.
        log(DateTime(2026, 9, 21)),
      ];
      expect(ReadingInsights.streakEndingOn(logs, DateTime(2026, 9, 20)), 3);
      expect(ReadingInsights.streakEndingOn(logs, DateTime(2026, 9, 21)), 4);
    });

    test('is zero when nothing was read that day', () {
      final logs = [log(DateTime(2026, 9, 19))];
      expect(ReadingInsights.streakEndingOn(logs, DateTime(2026, 9, 20)), 0);
      expect(
        ReadingInsights.streakEndingOn(
          [log(DateTime(2026, 9, 20), pages: 0)],
          DateTime(2026, 9, 20),
        ),
        0,
      );
    });
  });

  group('templates', () {
    Future<void> pumpCard(
      WidgetTester tester,
      ShareTemplate template, {
      ReadingShareData? data,
      String? place,
      String? quote,
    }) async {
      await tester.pumpApp(
        Scaffold(
          body: SingleChildScrollView(
            child: ReadingShareCard(
              data: data ?? session(),
              template: template,
              place: place,
              quote: quote,
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('every template shows the pages and the title', (tester) async {
      for (final template in ShareTemplate.values) {
        await pumpCard(tester, template);
        expect(find.text('47'), findsOneWidget, reason: '$template');
        // The cloth cover drawn without an image repeats the title.
        expect(find.text('Moby Dick'), findsWidgets, reason: '$template');
        expect(tester.takeException(), isNull, reason: '$template');
      }
    });

    testWidgets('stats card shows the range, the share of the book and streak',
        (tester) async {
      await pumpCard(tester, ShareTemplate.stats, place: 'Parco Sempione');

      expect(find.text('p. 186 → 233'), findsOneWidget);
      expect(find.text('34% di 688'), findsOneWidget);
      expect(find.text('Parco Sempione'), findsOneWidget);
      expect(find.text('54'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('poster: the cover color fills only the top, cream below',
        (tester) async {
      await pumpCard(tester, ShareTemplate.poster);
      final sizes = [
        for (final box in find
            .descendant(
              of: find.byType(ReadingShareCard),
              matching: find.byType(ColoredBox),
            )
            .evaluate())
          tester.getSize(find.byWidget(box.widget)),
      ];
      // The first box is the cream card, the next the poster band.
      expect(sizes.first, shareCardSize);
      expect(sizes[1], const Size(360, 270));
    });

    testWidgets('poster and photo cards list the figures', (tester) async {
      await pumpCard(tester, ShareTemplate.poster);
      // Poster's ticket splits each figure into its value and its unit.
      expect(find.text('52'), findsOneWidget);
      expect(find.text('min'), findsOneWidget);
      expect(find.text('54'), findsOneWidget);
      expect(find.text('pag/h'), findsOneWidget);
      expect(find.text('giorni'), findsOneWidget);

      await pumpCard(tester, ShareTemplate.photo);
      expect(find.text('52 min'), findsOneWidget);
      expect(find.text('54 pag/h'), findsOneWidget);
    });

    testWidgets('every template shows the place', (tester) async {
      for (final template in ShareTemplate.values) {
        await pumpCard(tester, template, place: 'Parco');
        // The poster folds the place into its bottom attribution line.
        final finder = template == ShareTemplate.poster
            ? find.textContaining('Parco')
            : find.text('Parco');
        expect(finder, findsOneWidget, reason: '$template');
      }
    });

    testWidgets(
        'every template shows a given quote closed with a quotation mark, '
        'none without one', (tester) async {
      for (final template in ShareTemplate.values) {
        await pumpCard(tester, template, quote: 'A whale is not a fish.');
        expect(
          find.text('A whale is not a fish.”'),
          findsOneWidget,
          reason: '$template',
        );
      }
      for (final template in ShareTemplate.values) {
        await pumpCard(tester, template);
        expect(
          find.textContaining('A whale is not a fish.'),
          findsNothing,
          reason: '$template',
        );
      }
    });

    testWidgets('every template takes a photo', (tester) async {
      final photo = MemoryImage(_pixel);
      for (final template in ShareTemplate.values) {
        await tester.pumpApp(
          Scaffold(
            body: SingleChildScrollView(
              child: ReadingShareCard(
                data: session(),
                template: template,
                photo: photo,
                place: 'Parco',
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.byType(Image), findsWidgets, reason: '$template');
        expect(tester.takeException(), isNull, reason: '$template');
      }
    });

    testWidgets('a time-only session with nothing else still draws',
        (tester) async {
      final bare = ReadingShareData(title: 'Dune', day: day, minutes: 20);
      for (final template in ShareTemplate.values) {
        await pumpCard(tester, template, data: bare);
        expect(find.text('20'), findsOneWidget, reason: '$template');
        expect(tester.takeException(), isNull, reason: '$template');
      }
    });

    testWidgets('long titles and big page counts do not overflow',
        (tester) async {
      final big = ReadingShareData(
        title: 'A very long title that goes on and on and on for far too long',
        author: 'An author with an equally long name, Jr., PhD',
        day: day,
        pages: 1234,
        minutes: 190,
        endPage: 1234,
        totalPages: 1500,
        streak: 120,
        // The week chart overflowed by 3 px on its tallest bar.
        weekPages: const [0, 0, 60, 0, 67, 13, 36],
      );
      for (final template in ShareTemplate.values) {
        await pumpCard(tester, template, data: big, place: 'x' * 40);
        expect(tester.takeException(), isNull, reason: '$template');
      }
    });
  });
}
