import 'package:bookshelf/core/errors/failure.dart';
import 'package:bookshelf/features/library/presentation/bloc/library_bloc.dart';
import 'package:bookshelf/features/scanner/presentation/cubit/isbn_scan_cubit.dart';
import 'package:bookshelf/features/scanner/presentation/widgets/scan_result_panel.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_app.dart';

class MockLibraryBloc extends MockBloc<LibraryEvent, LibraryState>
    implements LibraryBloc {}

void main() {
  Future<void> pumpPanel(
    WidgetTester tester,
    IsbnScanState state, {
    VoidCallback? onRescan,
  }) async {
    final library = MockLibraryBloc();
    whenListen(
      library,
      const Stream<LibraryState>.empty(),
      initialState: const LibraryState(),
    );
    await tester.pumpApp(
      BlocProvider<LibraryBloc>.value(
        value: library,
        child: Scaffold(
          body: ScanResultPanel(state: state, onRescan: onRescan ?? () {}),
        ),
      ),
    );
    // Not pumpAndSettle: the busy state has an endless spinner.
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('shows the hint while scanning', (tester) async {
    await pumpPanel(tester, const IsbnScanState());
    expect(
      find.text('Inquadra il codice a barre sul retro del libro'),
      findsOneWidget,
    );
  });

  testWidgets('shows progress while looking the book up', (tester) async {
    await pumpPanel(
      tester,
      const IsbnScanState(status: ScanStatus.lookingUp, isbn: '9780441172719'),
    );
    expect(find.text('Cerco il libro…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows the found book with its actions', (tester) async {
    var rescans = 0;
    await pumpPanel(
      tester,
      IsbnScanState(
        status: ScanStatus.found,
        isbn: '9780441172719',
        book: buildBook(),
      ),
      onRescan: () => rescans++,
    );

    expect(find.text('Frank Herbert · 1965'), findsOneWidget);
    expect(find.text('Dettagli'), findsOneWidget);
    expect(find.byTooltip('Aggiungi alla libreria'), findsOneWidget);

    await tester.tap(find.text('Scansiona un altro'));
    expect(rescans, 1);
  });

  testWidgets('explains when the ISBN is unknown', (tester) async {
    await pumpPanel(
      tester,
      const IsbnScanState(status: ScanStatus.notFound, isbn: '9780441172719'),
    );
    expect(
      find.text("Nessun libro trovato per l'ISBN 9780441172719"),
      findsOneWidget,
    );
    expect(find.text('Scansiona un altro'), findsOneWidget);
  });

  testWidgets('explains a failed lookup', (tester) async {
    await pumpPanel(
      tester,
      const IsbnScanState(
        status: ScanStatus.failure,
        isbn: '9780441172719',
        failure: Failure(FailureCode.network),
      ),
    );
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    expect(find.text('Scansiona un altro'), findsOneWidget);
  });
}
