import 'dart:async';
import 'dart:ui';

import 'package:bookshelf/features/library/domain/entities/book_loan.dart';
import 'package:bookshelf/features/library/domain/entities/user_book.dart';
import 'package:bookshelf/features/reminders/data/loan_reminders.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';
import 'reminders_test.dart' show FakeScheduler;

void main() {
  late MockLibraryRepository library;
  late StreamController<List<UserBook>> books;
  late FakeScheduler scheduler;
  late LoanReminders reminders;
  final now = DateTime(2026, 9, 27, 12);

  UserBook onLoan(String id, LoanKind kind, DateTime? due) =>
      buildUserBook(id: id).copyWith(
        loan: () => BookLoan(
          kind: kind,
          person: 'Anna',
          since: DateTime(2026, 9, 1),
          due: due,
        ),
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    library = MockLibraryRepository();
    books = StreamController<List<UserBook>>.broadcast();
    when(() => library.books).thenAnswer((_) => books.stream);
    scheduler = FakeScheduler();
    reminders = LoanReminders(
      await SharedPreferences.getInstance(),
      library,
      scheduler,
      now: () => now,
      locale: () => const Locale('it'),
    );
  });

  tearDown(() {
    reminders.dispose();
    books.close();
  });

  test('one notification on the morning of each future due date', () async {
    await reminders.update([
      onLoan('a', LoanKind.borrowed, DateTime(2026, 10, 3)),
      onLoan('b', LoanKind.lent, DateTime(2026, 9, 28)),
      onLoan('c', LoanKind.lent, DateTime(2026, 9, 20)), // already past
      onLoan('d', LoanKind.lent, null), // no due date
    ]);
    final scheduled = scheduler.scheduled.values.toList();
    expect(scheduled, hasLength(2));
    expect(scheduled[0].at, DateTime(2026, 9, 28, 10));
    expect(scheduled[0].body, 'Oggi Anna dovrebbe restituirti «Dune».');
    expect(scheduled[1].at, DateTime(2026, 10, 3, 10));
    expect(scheduled[1].title, 'Libro da restituire');
  });

  test('follows the library: a returned book loses its notification', () async {
    books.add([onLoan('a', LoanKind.borrowed, DateTime(2026, 10, 3))]);
    await pumpEventQueue();
    expect(scheduler.scheduled, hasLength(1));
    books.add([buildUserBook(id: 'a')]);
    await pumpEventQueue();
    expect(scheduler.scheduled, isEmpty);
  });

  test('asks for permission once; a refusal is not asked again', () async {
    scheduler.permission = false;
    final loan = [onLoan('a', LoanKind.borrowed, DateTime(2026, 10, 3))];
    await reminders.update(loan);
    expect(scheduler.scheduled, isEmpty);
    scheduler.permission = true;
    // Already asked: goes ahead (the system simply drops what it may not
    // show), without a second prompt.
    await reminders.update([
      onLoan('a', LoanKind.borrowed, DateTime(2026, 10, 4)),
    ]);
    expect(scheduler.scheduled, hasLength(1));
  });

  test('logout clears them', () async {
    await reminders.update([
      onLoan('a', LoanKind.borrowed, DateTime(2026, 10, 3)),
    ]);
    await reminders.clear();
    expect(scheduler.scheduled, isEmpty);
  });
}
