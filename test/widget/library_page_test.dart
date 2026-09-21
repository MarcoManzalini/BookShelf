import 'package:bloc_test/bloc_test.dart';
import 'package:bookshelf/core/errors/failure.dart';
import 'package:bookshelf/core/utils/request_status.dart';
import 'package:bookshelf/core/widgets/rating_bar.dart';
import 'package:bookshelf/features/library/domain/entities/reading_status.dart';
import 'package:bookshelf/features/library/presentation/bloc/library_bloc.dart';
import 'package:bookshelf/features/library/presentation/pages/library_page.dart';
import 'package:bookshelf/features/library/presentation/widgets/shelf_view.dart';
import 'package:bookshelf/features/library/presentation/widgets/swipe_view.dart';
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

    expect(find.text('Lo scaffale è vuoto'), findsOneWidget);
    expect(find.text('Cerca un libro'), findsOneWidget);
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

  final twoBooks = [
    buildUserBook(status: ReadingStatus.reading, currentPage: 100),
    buildUserBook(
      id: 'ub-2',
      book: buildBook(id: 'OL2W', title: 'Emma'),
      status: ReadingStatus.read,
    ),
  ];

  testWidgets('the shelf view puts the books on shelves', (tester) async {
    await pumpLibrary(
      tester,
      LibraryState(status: RequestStatus.success, books: twoBooks),
    );

    expect(find.byType(ShelfView), findsOneWidget);
    expect(find.byType(SwipeView), findsNothing);
    // Cloth covers (no image in the fixtures) carry the title.
    expect(find.text('Dune'), findsOneWidget);
    expect(find.text('Emma'), findsOneWidget);
  });

  testWidgets('the swipe view shows the focused book with its progress',
      (tester) async {
    await pumpLibrary(
      tester,
      LibraryState(
        status: RequestStatus.success,
        books: twoBooks,
        viewMode: LibraryViewMode.swipe,
      ),
    );

    expect(find.byType(SwipeView), findsOneWidget);
    expect(find.text('100 / 400 pagine'), findsOneWidget);
    expect(find.text('In lettura'), findsOneWidget);
  });

  testWidgets('the swipe view follows the swiped book', (tester) async {
    await pumpLibrary(
      tester,
      LibraryState(
        status: RequestStatus.success,
        books: twoBooks,
        viewMode: LibraryViewMode.swipe,
      ),
    );

    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pumpAndSettle();

    expect(find.text('100 / 400 pagine'), findsNothing);
    expect(find.text('Letto'), findsOneWidget);
  });

  testWidgets('choosing a status in the filter sheet dispatches the filter',
      (tester) async {
    await pumpLibrary(
      tester,
      const LibraryState(status: RequestStatus.success),
    );

    await tester.tap(find.byTooltip('Filtra la libreria'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'In lettura'));

    verify(() => bloc.add(const LibraryFilterChanged(LibraryFilter.reading)))
        .called(1);
  });

  testWidgets('the layout toggle dispatches LibraryViewModeToggled',
      (tester) async {
    await pumpLibrary(
      tester,
      const LibraryState(status: RequestStatus.success),
    );

    await tester.tap(find.byTooltip('Vista a scorrimento'));

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
