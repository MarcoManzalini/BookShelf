import 'package:bloc_test/bloc_test.dart';
import 'package:bookshelf/core/errors/failure.dart';
import 'package:bookshelf/core/utils/request_status.dart';
import 'package:bookshelf/core/widgets/rating_bar.dart';
import 'package:bookshelf/features/library/domain/entities/reading_status.dart';
import 'package:bookshelf/features/library/presentation/bloc/library_bloc.dart';
import 'package:bookshelf/features/library/presentation/pages/library_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_app.dart';

class MockLibraryBloc extends MockBloc<LibraryEvent, LibraryState>
    implements LibraryBloc {}

void main() {
  late MockLibraryBloc bloc;

  setUpAll(() => registerFallbackValue(const LibraryStarted()));

  setUp(() => bloc = MockLibraryBloc());

  Future<void> pumpLibrary(WidgetTester tester, LibraryState state) {
    when(() => bloc.state).thenReturn(state);
    return tester.pumpApp(
      BlocProvider<LibraryBloc>.value(value: bloc, child: const LibraryPage()),
    );
  }

  testWidgets('shows the empty state for a new user', (tester) async {
    await pumpLibrary(
      tester,
      const LibraryState(status: RequestStatus.success),
    );

    expect(find.text('La tua libreria è vuota'), findsOneWidget);
    expect(find.text('Cerca libri'), findsOneWidget);
  });

  testWidgets('shows an error with retry when the first load fails',
      (tester) async {
    await pumpLibrary(
      tester,
      const LibraryState(
        status: RequestStatus.failure,
        failure: Failure(FailureCode.network),
      ),
    );

    expect(find.text('Sei offline'), findsOneWidget);
    await tester.tap(find.text('Riprova'));
    verify(() => bloc.add(const LibraryStarted())).called(1);
  });

  testWidgets('lists books with status and progress', (tester) async {
    await pumpLibrary(
      tester,
      LibraryState(
        status: RequestStatus.success,
        books: [
          buildUserBook(
            status: ReadingStatus.reading,
            currentPage: 100,
          ),
          buildUserBook(
            id: 'ub-2',
            book: buildBook(id: 'OL2W', title: 'Emma'),
            status: ReadingStatus.read,
          ),
        ],
      ),
    );

    expect(find.text('Dune'), findsOneWidget);
    expect(find.text('Emma'), findsOneWidget);
    expect(find.text('100 / 400 pagine'), findsOneWidget);
    expect(find.text('Letto'), findsWidgets);
  });

  testWidgets('tapping a filter chip dispatches LibraryFilterChanged',
      (tester) async {
    await pumpLibrary(
      tester,
      const LibraryState(status: RequestStatus.success),
    );

    await tester.tap(find.widgetWithText(ChoiceChip, 'In lettura'));

    verify(() => bloc.add(const LibraryFilterChanged(LibraryFilter.reading)))
        .called(1);
  });

  testWidgets('the layout toggle dispatches LibraryViewModeToggled',
      (tester) async {
    await pumpLibrary(
      tester,
      const LibraryState(status: RequestStatus.success),
    );

    await tester.tap(find.byTooltip('Vista griglia'));

    verify(() => bloc.add(const LibraryViewModeToggled())).called(1);
  });

  testWidgets('AppRatingBar: tapping the current star clears the rating',
      (tester) async {
    int? rating = 3;
    await tester.pumpApp(
      StatefulBuilder(
        builder: (context, setState) => Scaffold(
          body: AppRatingBar(
            rating: rating,
            onChanged: (value) => setState(() => rating = value),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('star_5')));
    await tester.pump();
    expect(rating, 5);

    await tester.tap(find.byKey(const ValueKey('star_5')));
    await tester.pump();
    expect(rating, isNull);
  });
}
