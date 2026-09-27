import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:bookshelf/core/utils/request_status.dart';
import 'package:bookshelf/features/book_details/presentation/bloc/book_details_bloc.dart';
import 'package:bookshelf/features/book_details/presentation/widgets/book_format_section.dart';
import 'package:bookshelf/features/book_details/presentation/widgets/loan_section.dart';
import 'package:bookshelf/features/book_details/presentation/widgets/quotes_section.dart';
import 'package:bookshelf/features/book_details/presentation/widgets/series_section.dart';
import 'package:bookshelf/features/book_details/presentation/widgets/shelves_section.dart';
import 'package:bookshelf/features/library/presentation/bloc/library_bloc.dart';
import 'package:bookshelf/features/book_details/presentation/widgets/vibe_section.dart';
import 'package:bookshelf/features/library/domain/entities/book_format.dart';
import 'package:bookshelf/features/library/domain/entities/book_loan.dart';
import 'package:bookshelf/features/library/domain/entities/book_series.dart';
import 'package:bookshelf/features/library/domain/entities/book_vibe.dart';
import 'package:bookshelf/features/recap/domain/reading_recap.dart';
import 'package:bookshelf/features/recap/presentation/widgets/recap_share_card.dart';
import 'package:bookshelf/features/search/domain/entities/book.dart';
import 'package:bookshelf/features/book_details/presentation/widgets/reading_dates_section.dart';
import 'package:bookshelf/features/book_details/presentation/widgets/reading_sessions_list.dart';
import 'package:bookshelf/features/stats/domain/entities/reading_log.dart';
import 'package:bookshelf/features/library/domain/entities/book_read.dart';
import 'package:bookshelf/features/library/domain/entities/reading_status.dart';
import 'package:bookshelf/features/library/presentation/widgets/status_picker_sheet.dart';
import 'package:bookshelf/features/quotes/domain/entities/book_quote.dart';
import 'package:bookshelf/features/reminders/data/reading_reminders.dart';
import 'package:bookshelf/features/reminders/presentation/reminder_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/reminders/reminders_test.dart' show FakeScheduler;
import '../helpers/fixtures.dart';
import '../helpers/mocks.dart';
import '../helpers/pump_app.dart';

class MockLibraryBloc extends MockBloc<LibraryEvent, LibraryState>
    implements LibraryBloc {}

class MockBookDetailsBloc extends MockBloc<BookDetailsEvent, BookDetailsState>
    implements BookDetailsBloc {}

void main() {
  late MockBookDetailsBloc bloc;

  setUpAll(() => registerFallbackValue(const BookDetailsRereadStarted()));

  setUp(() {
    bloc = MockBookDetailsBloc();
    when(() => bloc.state)
        .thenReturn(const BookDetailsState(status: RequestStatus.success));
  });

  Widget withBloc(Widget child) => BlocProvider<BookDetailsBloc>.value(
        value: bloc,
        child: Scaffold(body: SingleChildScrollView(child: child)),
      );

  testWidgets('adding a book offers only the three starting statuses',
      (tester) async {
    await tester.pumpApp(
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showStatusPickerSheet(context),
          child: const Text('open'),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Da leggere'), findsOneWidget);
    expect(find.text('In pausa'), findsNothing);
    expect(find.text('Abbandonato'), findsNothing);
  });

  group('reading dates', () {
    final finished = buildUserBook(
      status: ReadingStatus.read,
      finishedAt: DateTime(2026, 2, 1),
    );

    testWidgets('a finished book can be read again, after confirming',
        (tester) async {
      await tester.pumpApp(withBloc(ReadingDatesSection(userBook: finished)));
      await tester.tap(find.widgetWithText(TextButton, 'Rileggi'));
      await tester.pumpAndSettle();
      expect(find.text('Iniziare una nuova lettura?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Rileggi'));
      await tester.pumpAndSettle();
      verify(() => bloc.add(const BookDetailsRereadStarted())).called(1);
    });

    testWidgets('lists earlier reads with the total', (tester) async {
      final twice = finished.copyWith(
        pastReads: [BookRead(finishedAt: DateTime(2020, 5, 3))],
      );
      await tester.pumpApp(withBloc(ReadingDatesSection(userBook: twice)));
      expect(find.text('Letture precedenti'), findsOneWidget);
      expect(find.text('Letto 2 volte'), findsOneWidget);
      await tester.tap(find.byTooltip('Rimuovi questa lettura'));
      verify(
        () => bloc.add(
          BookDetailsPastReadRemoved(BookRead(finishedAt: DateTime(2020, 5, 3))),
        ),
      ).called(1);
    });

    testWidgets('no re-read button before the book is finished',
        (tester) async {
      await tester.pumpApp(
        withBloc(
          ReadingDatesSection(
            userBook: buildUserBook(status: ReadingStatus.paused),
          ),
        ),
      );
      expect(find.widgetWithText(TextButton, 'Rileggi'), findsNothing);
      expect(find.text('Aggiungi una lettura precedente'), findsOneWidget);
    });
  });

  group('quotes', () {
    testWidgets('empty: explains, and the editor saves a typed quote',
        (tester) async {
      await tester.pumpApp(withBloc(const QuotesSection(quotes: [])));
      expect(find.textContaining('Salva i passaggi'), findsOneWidget);

      await tester.tap(find.text('Aggiungi citazione'));
      await tester.pumpAndSettle();
      // Saving needs some text.
      final save = find.widgetWithText(FilledButton, 'Salva');
      expect(tester.widget<FilledButton>(save).onPressed, isNull);

      await tester.enterText(find.byType(TextField).first, 'La paura uccide.');
      await tester.enterText(find.byType(TextField).last, '12');
      await tester.pump();
      await tester.tap(save);
      await tester.pumpAndSettle();
      verify(
        () => bloc.add(
          const BookDetailsQuoteSaved(text: 'La paura uccide.', page: 12),
        ),
      ).called(1);
    });

    testWidgets('the editor can be closed without saving', (tester) async {
      await tester.pumpApp(withBloc(const QuotesSection(quotes: [])));
      await tester.tap(find.text('Aggiungi citazione'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Chiudi'));
      await tester.pumpAndSettle();
      expect(find.text('Fotografa la pagina'), findsNothing);
      verifyNever(() => bloc.add(any()));
    });

    testWidgets('shows saved quotes with their page', (tester) async {
      await tester.pumpApp(
        withBloc(
          QuotesSection(
            quotes: [
              BookQuote(
                id: 'q1',
                userBookId: 'ub-1',
                text: 'Non devo avere paura.',
                page: 12,
                createdAt: DateTime(2026),
              ),
            ],
          ),
        ),
      );
      expect(find.text('«Non devo avere paura.»'), findsOneWidget);
      expect(find.text('p. 12'), findsOneWidget);
    });
  });

  testWidgets('reminder tile turns reminders on and shows the time',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final logs = MockReadingLogRepository();
    final library = MockLibraryRepository();
    final changes = StreamController<void>.broadcast();
    addTearDown(changes.close);
    when(() => logs.changes).thenAnswer((_) => changes.stream);
    when(() => logs.all(since: any(named: 'since')))
        .thenAnswer((_) async => []);
    when(() => library.cachedBooks).thenReturn([]);
    final reminders = ReadingReminders(
      await SharedPreferences.getInstance(),
      logs,
      library,
      FakeScheduler(),
    );

    await tester.pumpApp(
      Scaffold(body: ReminderTile(reminders: reminders)),
    );
    expect(find.text('Promemoria di lettura'), findsOneWidget);
    expect(find.text('Cambia orario'), findsNothing);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(reminders.enabled, isTrue);
    expect(find.text('Ogni giorno alle 21:00'), findsOneWidget);
    expect(find.text('Cambia orario'), findsOneWidget);
  });

  group('format, series, mood and loan sections', () {
    testWidgets('an audiobook asks for its length', (tester) async {
      await tester.pumpApp(
        withBloc(
          BookFormatSection(
            userBook: buildUserBook().copyWith(format: BookFormat.audio),
          ),
        ),
      );
      expect(find.text("Imposta la durata dell'audiolibro"), findsOneWidget);
      await tester.tap(find.text('Ebook'));
      verify(
        () => bloc.add(const BookDetailsFormatChanged(BookFormat.ebook)),
      ).called(1);
    });

    testWidgets('series shows the volumes and the others in the library',
        (tester) async {
      final first = buildUserBook(id: 'one').copyWith(
        series: () =>
            const BookSeries(name: '1Q84', index: 1, indexEnd: 2, total: 3),
      );
      final second = buildUserBook(
        id: 'two',
        book: const Book(externalId: 'OL2W', title: '1Q84 Libro 3'),
      ).copyWith(series: () => const BookSeries(name: '1q84', index: 3));
      await tester.pumpApp(
        withBloc(SeriesSection(userBook: first, library: [first, second])),
      );
      expect(find.text('Volumi 1–2 di 3'), findsOneWidget);
      expect(find.text('1Q84 Libro 3'), findsOneWidget);
      expect(find.text('Volume 3'), findsOneWidget);
    });

    testWidgets('adding a book to an existing saga suggests the next volume',
        (tester) async {
      final first = buildUserBook(id: 'one').copyWith(
        series: () =>
            const BookSeries(name: '1Q84', index: 1, indexEnd: 2, total: 3),
      );
      final book = buildUserBook(
        id: 'two',
        book: const Book(externalId: 'OL2W', title: '1Q84 Libro 3'),
      );
      await tester.pumpApp(
        withBloc(SeriesSection(userBook: book, library: [first, book])),
      );
      await tester.tap(find.text('Aggiungi a una saga'));
      await tester.pumpAndSettle();
      expect(find.text('Scegli la saga'), findsOneWidget);
      expect(find.text('1Q84'), findsOneWidget);
      expect(
        find.text('1 libro nella tua libreria · 3 volumi'),
        findsOneWidget,
      );

      await tester.tap(find.text('1Q84'));
      await tester.pumpAndSettle();
      final fields = tester
          .widgetList<TextFormField>(find.byType(TextFormField))
          .map((f) => f.controller!.text)
          .toList();
      expect(fields, ['3', '', '3']);

      await tester.tap(find.widgetWithText(FilledButton, 'Salva'));
      await tester.pumpAndSettle();
      verify(
        () => bloc.add(
          const BookDetailsSeriesChanged(
            BookSeries(name: '1Q84', index: 3, total: 3),
          ),
        ),
      ).called(1);
    });

    testWidgets('a new saga can hold volumes 1-2 in one book', (tester) async {
      final book = buildUserBook();
      await tester.pumpApp(
        withBloc(SeriesSection(userBook: book, library: [book])),
      );
      await tester.tap(find.text('Aggiungi a una saga'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '1Q84');
      await tester.pump();
      await tester.tap(find.text('Crea «1Q84»'));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(1), '1');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Salva'));
      await tester.pump();
      // "To" must come after "from".
      expect(find.text('Deve venire dopo il primo volume'), findsOneWidget);

      await tester.enterText(fields.at(1), '2');
      await tester.enterText(fields.at(2), '3');
      await tester.tap(find.widgetWithText(FilledButton, 'Salva'));
      await tester.pumpAndSettle();
      verify(
        () => bloc.add(
          const BookDetailsSeriesChanged(
            BookSeries(name: '1Q84', index: 1, indexEnd: 2, total: 3),
          ),
        ),
      ).called(1);
    });

    testWidgets('a fourth mood cannot be picked', (tester) async {
      await tester.pumpApp(
        withBloc(
          VibeSection(
            userBook: buildUserBook().copyWith(
              moods: [BookMood.dark, BookMood.sad, BookMood.tense],
            ),
          ),
        ),
      );
      final funny = find.widgetWithText(FilterChip, 'Divertente');
      expect(tester.widget<FilterChip>(funny).onSelected, isNull);
      await tester.tap(find.text('Veloce'));
      verify(
        () => bloc.add(const BookDetailsPaceChanged(ReadingPace.fast)),
      ).called(1);
    });

    testWidgets('an overdue loan is flagged and can be closed',
        (tester) async {
      await tester.pumpApp(
        withBloc(
          LoanSection(
            now: DateTime(2026, 10, 10),
            userBook: buildUserBook().copyWith(
              loan: () => BookLoan(
                kind: LoanKind.borrowed,
                person: 'Biblioteca Sormani',
                since: DateTime(2026, 9, 1),
                due: DateTime(2026, 10, 1),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Preso da Biblioteca Sormani'), findsOneWidget);
      expect(find.text('In ritardo'), findsOneWidget);
      await tester.tap(find.text('Restituito'));
      verify(() => bloc.add(const BookDetailsLoanChanged(null))).called(1);
    });
  });

  testWidgets('recap card draws the key numbers', (tester) async {
    final recap = ReadingRecap.compute(
      period: const RecapPeriod.year(2026),
      books: [
        buildUserBook(
          status: ReadingStatus.read,
          rating: 5,
          finishedAt: DateTime(2026, 3, 1),
        ),
      ],
      logs: const [],
    );
    await tester.pumpApp(
      Center(
        child: FittedBox(
          child: RecapShareCard(recap: recap, title: 'Il tuo 2026'),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Il tuo 2026'), findsOneWidget);
    expect(find.text('libro finito'), findsOneWidget);
    expect(find.text('400'), findsOneWidget);
    expect(find.text('Dune'), findsWidgets);
  });

  testWidgets('sessions are paged five at a time', (tester) async {
    final logs = [
      for (var i = 12; i >= 1; i--)
        ReadingLog(
          id: 'l$i',
          userBookId: 'ub-1',
          loggedOn: DateTime(2026, 9, i),
          pages: i,
        ),
    ];
    await tester.pumpApp(
      Scaffold(body: ReadingSessionsList(logs: logs)),
    );
    expect(find.text('1–5 di 12'), findsOneWidget);
    expect(find.text('12 pagine'), findsOneWidget);
    expect(find.text('7 pagine'), findsNothing);

    await tester.tap(find.byTooltip('Meno recenti'));
    await tester.pump();
    expect(find.text('6–10 di 12'), findsOneWidget);
    expect(find.text('7 pagine'), findsOneWidget);

    await tester.tap(find.byTooltip('Meno recenti'));
    await tester.pump();
    expect(find.text('11–12 di 12'), findsOneWidget);
    final older = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.chevron_right_rounded),
    );
    expect(older.onPressed, isNull);

    // A new session brings the list back to the first page.
    await tester.pumpApp(
      Scaffold(
        body: ReadingSessionsList(
          logs: [
            ReadingLog(
              id: 'new',
              userBookId: 'ub-1',
              loggedOn: DateTime(2026, 9, 13),
              pages: 40,
            ),
            ...logs,
          ],
        ),
      ),
    );
    expect(find.text('1–5 di 13'), findsOneWidget);
  });

  testWidgets('a shelf typed and saved without + is created, with feedback',
      (tester) async {
    final library = MockLibraryBloc();
    when(() => library.state).thenReturn(const LibraryState());
    await tester.pumpApp(
      BlocProvider<LibraryBloc>.value(
        value: library,
        child: withBloc(ShelvesSection(userBook: buildUserBook())),
      ),
    );
    await tester.tap(find.text('Aggiungi scaffale'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '  Regali ');
    await tester.tap(find.widgetWithText(FilledButton, 'Salva'));
    await tester.pumpAndSettle();

    verify(() => bloc.add(const BookDetailsShelvesChanged(['Regali'])))
        .called(1);
    expect(find.text('Aggiunto a «Regali»'), findsOneWidget);
  });

  testWidgets('a new shelf appears ticked at the top of the list',
      (tester) async {
    final library = MockLibraryBloc();
    when(() => library.state).thenReturn(
      LibraryState(
        books: [
          for (final (i, name) in ['A', 'B', 'C'].indexed)
            buildUserBook(id: 'b$i').copyWith(shelves: [name]),
        ],
      ),
    );
    await tester.pumpApp(
      BlocProvider<LibraryBloc>.value(
        value: library,
        child: withBloc(ShelvesSection(userBook: buildUserBook())),
      ),
    );
    await tester.tap(find.text('Aggiungi scaffale'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Regali');
    await tester.tap(find.byTooltip('Aggiungi scaffale').last);
    await tester.pump();

    final tiles = tester
        .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
        .toList();
    expect((tiles.first.title! as Text).data, 'Regali');
    expect(tiles.first.value, isTrue);
  });
}
