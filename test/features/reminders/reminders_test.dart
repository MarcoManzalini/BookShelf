import 'dart:async';
import 'dart:ui';

import 'package:bookshelf/core/errors/failure.dart';
import 'package:bookshelf/features/library/domain/entities/reading_status.dart';
import 'package:bookshelf/features/quotes/data/text_recognizer.dart';
import 'package:bookshelf/features/reminders/data/reading_reminders.dart';
import 'package:bookshelf/features/reminders/data/reminder_scheduler.dart';
import 'package:bookshelf/features/reminders/domain/reminder_plan.dart';
import 'package:bookshelf/features/stats/domain/entities/reading_log.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';

class FakeScheduler implements ReminderScheduler {
  bool permission = true;
  final scheduled = <int, ({DateTime at, String title, String body})>{};

  @override
  Future<bool> requestPermission() async => permission;

  @override
  Future<void> schedule({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required String channelName,
  }) async =>
      scheduled[id] = (at: at, title: title, body: body);

  @override
  Future<void> cancel(int id) async => scheduled.remove(id);
}

ReadingLog log(DateTime day, {String book = 'ub-1', int pages = 10}) =>
    ReadingLog(id: '$day', userBookId: book, loggedOn: day, pages: pages);

void main() {
  group('ReminderPlan', () {
    List<ReminderSlot> plan(DateTime now, List<DateTime> active) =>
        ReminderPlan.compute(
          now: now,
          hour: 21,
          minute: 0,
          activeDays: active,
          bookTitle: 'Dune',
        );

    test('before the time, with a streak and nothing read today', () {
      final slots = plan(DateTime(2026, 9, 27, 10), [
        DateTime(2026, 9, 26),
        DateTime(2026, 9, 25),
      ]);
      expect(slots, hasLength(7));
      expect(
        slots.first,
        ReminderSlot(DateTime(2026, 9, 27, 21), const StreakReminder(2)),
      );
      expect(slots[1].message, const NudgeReminder('Dune'));
      expect(slots.last.at, DateTime(2026, 10, 3, 21));
    });

    test('already read today: nothing today, the streak tomorrow', () {
      final slots = plan(DateTime(2026, 9, 27, 10), [
        DateTime(2026, 9, 27),
        DateTime(2026, 9, 26),
      ]);
      expect(slots, hasLength(6));
      expect(
        slots.first,
        ReminderSlot(DateTime(2026, 9, 28, 21), const StreakReminder(2)),
      );
    });

    test('past the time without reading: the streak is gone tomorrow', () {
      final slots = plan(DateTime(2026, 9, 27, 22), [DateTime(2026, 9, 26)]);
      expect(slots.first.at, DateTime(2026, 9, 28, 21));
      expect(slots.every((s) => s.message is NudgeReminder), isTrue);
    });

    test('keeps the wall-clock time across a daylight saving change', () {
      final slots = plan(DateTime(2026, 10, 23, 10), const []);
      expect(slots.map((s) => s.at.hour).toSet(), {21});
    });
  });

  group('ReadingReminders', () {
    late MockReadingLogRepository logs;
    late MockLibraryRepository library;
    late FakeScheduler scheduler;
    late StreamController<void> changes;
    late ReadingReminders reminders;
    final now = DateTime(2026, 9, 27, 10);

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      logs = MockReadingLogRepository();
      library = MockLibraryRepository();
      scheduler = FakeScheduler();
      changes = StreamController<void>.broadcast();
      when(() => logs.changes).thenAnswer((_) => changes.stream);
      when(() => logs.all(since: any(named: 'since'))).thenAnswer(
        (_) async => [log(DateTime(2026, 9, 26)), log(DateTime(2026, 9, 25))],
      );
      when(() => library.cachedBooks).thenReturn([
        buildUserBook(status: ReadingStatus.reading),
      ]);
      reminders = ReadingReminders(
        await SharedPreferences.getInstance(),
        logs,
        library,
        scheduler,
        now: () => now,
        locale: () => const Locale('it'),
      );
    });

    tearDown(() => changes.close());

    test('is off by default and schedules nothing', () async {
      await reminders.refresh();
      expect(reminders.enabled, isFalse);
      expect(scheduler.scheduled, isEmpty);
    });

    test('turning it on schedules a week, the first about the streak',
        () async {
      expect(await reminders.enable(), isTrue);
      expect(scheduler.scheduled, hasLength(7));
      final first = scheduler.scheduled.values.first;
      expect(first.at, DateTime(2026, 9, 27, 21));
      expect(first.title, 'Non perdere la tua serie');
      expect(first.body, contains('2 giorni di fila'));
      expect(scheduler.scheduled.values.last.body, contains('«Dune»'));
    });

    test('refused permission leaves it off', () async {
      scheduler.permission = false;
      expect(await reminders.enable(), isFalse);
      expect(reminders.enabled, isFalse);
      expect(scheduler.scheduled, isEmpty);
    });

    test('a new session reschedules; turning it off cancels all', () async {
      await reminders.enable();
      when(() => logs.all(since: any(named: 'since'))).thenAnswer(
        (_) async => [log(DateTime(2026, 9, 27)), log(DateTime(2026, 9, 26))],
      );
      changes.add(null);
      await pumpEventQueue();
      expect(scheduler.scheduled, hasLength(6));
      expect(scheduler.scheduled.values.first.at, DateTime(2026, 9, 28, 21));

      await reminders.disable();
      expect(scheduler.scheduled, isEmpty);
    });

    test('offline: keeps what is already scheduled', () async {
      await reminders.enable();
      when(() => logs.all(since: any(named: 'since')))
          .thenThrow(const Failure(FailureCode.network));
      await reminders.refresh();
      expect(scheduler.scheduled, hasLength(7));
    });

    test('the time can be changed', () async {
      await reminders.enable();
      await reminders.setTime(8 * 60 + 30);
      expect(reminders.minutes, 510);
      expect(scheduler.scheduled.values.first.at, DateTime(2026, 9, 28, 8, 30));
    });
  });

  group('TextRecognizer.joinLines', () {
    test('joins printed lines and hyphenated words', () {
      expect(
        TextRecognizer.joinLines([
          'Non devo avere pau-',
          'ra. La paura uccide',
          '',
          '  la mente.  ',
        ]),
        'Non devo avere paura. La paura uccide la mente.',
      );
      expect(TextRecognizer.joinLines(const []), '');
    });
  });
}
