import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:bookshelf/core/utils/request_status.dart';
import 'package:bookshelf/features/book_details/presentation/widgets/shelf_picker_sheet.dart';
import 'package:bookshelf/features/library/domain/entities/reading_status.dart';
import 'package:bookshelf/features/library/presentation/bloc/library_bloc.dart';
import 'package:bookshelf/features/library/presentation/pages/library_page.dart';
import 'package:bookshelf/features/profile/domain/entities/profile.dart';
import 'package:bookshelf/features/profile/domain/repositories/profile_repository.dart';
import 'package:bookshelf/features/profile/presentation/widgets/profile_shelves.dart';
import 'package:bookshelf/features/stats/domain/entities/reading_log.dart';
import 'package:bookshelf/features/stats/presentation/cubit/stats_cubit.dart';
import 'package:bookshelf/features/stats/presentation/pages/stats_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fixtures.dart';
import '../helpers/mocks.dart';
import '../helpers/pump_app.dart';

class MockLibraryBloc extends MockBloc<LibraryEvent, LibraryState>
    implements LibraryBloc {}

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockLibraryBloc library;

  setUp(() => library = MockLibraryBloc());

  Widget withLibrary(LibraryState state, Widget child) {
    when(() => library.state).thenReturn(state);
    return BlocProvider<LibraryBloc>.value(value: library, child: child);
  }

  group('offline banner', () {
    testWidgets('appears with the pending count and retries on tap',
        (tester) async {
      await tester.pumpApp(
        withLibrary(
          const LibraryState(
            status: RequestStatus.success,
            offline: true,
            pendingChanges: 3,
          ),
          const LibraryPage(),
        ),
      );

      expect(find.textContaining('Sei offline'), findsOneWidget);
      expect(find.text('3 modifiche da sincronizzare'), findsOneWidget);

      await tester.tap(find.text('Riprova').first);
      verify(() => library.add(const LibraryRefreshRequested())).called(1);
    });

    testWidgets('is absent when online', (tester) async {
      await tester.pumpApp(
        withLibrary(
          const LibraryState(status: RequestStatus.success),
          const LibraryPage(),
        ),
      );
      expect(find.textContaining('Sei offline'), findsNothing);
    });
  });

  group('shelves', () {
    final books = [
      buildUserBook(id: 'a').copyWith(shelves: const ['Regali', 'Estate']),
      buildUserBook(
        id: 'b',
        book: buildBook(id: 'OL2W', title: 'Emma'),
      ).copyWith(shelves: const ['Regali']),
    ];

    testWidgets('the profile lists shelves with their counts', (tester) async {
      await tester.pumpApp(
        withLibrary(
          LibraryState(status: RequestStatus.success, books: books),
          const Scaffold(body: ProfileShelves()),
        ),
      );
      expect(find.text('Regali'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Estate'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('the profile shows nothing without shelves', (tester) async {
      await tester.pumpApp(
        withLibrary(
          const LibraryState(status: RequestStatus.success),
          const Scaffold(body: ProfileShelves()),
        ),
      );
      expect(find.text('I miei scaffali'), findsNothing);
    });

    testWidgets('the library shows the active shelf and lets you clear it',
        (tester) async {
      await tester.pumpApp(
        withLibrary(
          LibraryState(
            status: RequestStatus.success,
            books: books,
            shelfFilter: 'Regali',
          ),
          const LibraryPage(),
        ),
      );
      expect(find.text('Scaffale: Regali'), findsOneWidget);

      await tester.tap(
        find
            .descendant(of: find.byType(InputChip), matching: find.byType(Icon))
            .last,
      );
      verify(() => library.add(const LibraryShelfFilterChanged(null)))
          .called(1);
    });

    testWidgets('the picker creates a shelf, selects it and returns the list',
        (tester) async {
      List<String>? result;
      await tester.pumpApp(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => result = await showShelfPickerSheet(
                context,
                current: const ['Regali'],
                available: const ['Regali', 'Estate'],
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Estate'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Inverno');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.tap(find.text('Estate'));
      await tester.pump();
      await tester.tap(find.text('Salva'));
      await tester.pumpAndSettle();

      expect(result, unorderedEquals(['Regali', 'Inverno', 'Estate']));
    });

    testWidgets('typing an existing name in another case does not duplicate',
        (tester) async {
      List<String>? result;
      await tester.pumpApp(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => result = await showShelfPickerSheet(
                context,
                current: const [],
                available: const ['Regali'],
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '  regali ');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.tap(find.text('Salva'));
      await tester.pumpAndSettle();

      expect(result, ['Regali']);
    });
  });

  group('statistics page', () {
    testWidgets('renders goal, tiles and charts without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final logs = MockReadingLogRepository();
      final profiles = MockProfileRepository();
      final today = DateTime.now();
      when(() => logs.all(since: any(named: 'since'))).thenAnswer(
        (_) async => [
          ReadingLog(
            id: 'l1',
            userBookId: 'ub-1',
            loggedOn: DateTime(today.year, today.month, today.day),
            pages: 25,
            minutes: 40,
          ),
        ],
      );
      when(() => profiles.getProfile())
          .thenAnswer((_) async => const Profile(id: 'u', readingGoal: 10));
      final cubit = StatsCubit(logs, profiles);
      unawaited(cubit.load());

      await tester.pumpApp(
        withLibrary(
          LibraryState(
            status: RequestStatus.success,
            books: [
              buildUserBook(
                status: ReadingStatus.read,
                rating: 4,
                finishedAt: DateTime(today.year, 1, 5),
              ),
            ],
          ),
          BlocProvider.value(value: cubit, child: const StatsView()),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('1 di 10 libri'), findsOneWidget);
      expect(find.text('Giorni di fila'), findsOneWidget);
      expect(find.text('Libri per mese'), findsOneWidget);
      expect(find.text('0.7 h'), findsOneWidget);
    });

    testWidgets('invites the reader to set a goal when there is none',
        (tester) async {
      final logs = MockReadingLogRepository();
      final profiles = MockProfileRepository();
      when(() => logs.all(since: any(named: 'since')))
          .thenAnswer((_) async => []);
      when(() => profiles.getProfile())
          .thenAnswer((_) async => const Profile(id: 'u'));
      final cubit = StatsCubit(logs, profiles);
      unawaited(cubit.load());

      await tester.pumpApp(
        withLibrary(
          const LibraryState(status: RequestStatus.success),
          BlocProvider.value(value: cubit, child: const StatsView()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Imposta un obiettivo annuale'), findsOneWidget);
    });
  });
}
