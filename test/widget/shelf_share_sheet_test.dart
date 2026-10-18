import 'package:bloc_test/bloc_test.dart';
import 'package:bookshelf/core/utils/request_status.dart';
import 'package:bookshelf/features/shelf_share/domain/entities/shelf_share.dart';
import 'package:bookshelf/features/shelf_share/presentation/cubit/shelf_share_cubit.dart';
import 'package:bookshelf/features/shelf_share/presentation/widgets/shelf_share_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_app.dart';

class MockShelfShareCubit extends MockCubit<ShelfShareState>
    implements ShelfShareCubit {}

void main() {
  late MockShelfShareCubit cubit;

  setUp(() => cubit = MockShelfShareCubit());

  Future<void> pump(WidgetTester tester, ShelfShareState state) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    when(() => cubit.state).thenReturn(state);
    await tester.pumpApp(
      Scaffold(
        body: BlocProvider<ShelfShareCubit>.value(
          value: cubit,
          child: ShelfShareSheet(shelfName: 'Regali', books: [buildBook()]),
        ),
      ),
    );
  }

  testWidgets('shows only share and copy when not shared yet', (tester) async {
    await pump(tester, const ShelfShareState(status: RequestStatus.success));

    expect(find.text('Condividi «Regali»'), findsOneWidget);
    expect(find.text('Condividi'), findsOneWidget);
    expect(find.text('Copia link'), findsOneWidget);
    expect(find.text('Nuovo link'), findsNothing);
    expect(find.text('Interrompi condivisione'), findsNothing);
  });

  testWidgets('shows regenerate and stop when shared', (tester) async {
    await pump(
      tester,
      const ShelfShareState(
        status: RequestStatus.success,
        share: ShelfShare(shelfName: 'Regali', token: 't'),
      ),
    );

    expect(find.text('Nuovo link'), findsOneWidget);
    expect(find.text('Interrompi condivisione'), findsOneWidget);
  });

  testWidgets('copy confirms inside the sheet', (tester) async {
    const share = ShelfShare(shelfName: 'Regali', token: 't');
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    when(() => cubit.ensureShare()).thenAnswer((_) async => share);
    await pump(
      tester,
      const ShelfShareState(status: RequestStatus.success, share: share),
    );

    await tester.tap(find.text('Copia link'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(ShelfShareSheet),
        matching: find.text('Link copiato'),
      ),
      findsOneWidget,
    );
    expect(copied, 'https://marcomanzalini.github.io/BookShelf/s/?t=t');
  });

  testWidgets('stop asks for confirmation before revoking', (tester) async {
    when(() => cubit.stop()).thenAnswer((_) async {});
    await pump(
      tester,
      const ShelfShareState(
        status: RequestStatus.success,
        share: ShelfShare(shelfName: 'Regali', token: 't'),
      ),
    );

    await tester.tap(find.text('Interrompi condivisione'));
    await tester.pumpAndSettle();
    expect(
      find.text('Chi ha il link non vedrà più questo scaffale.'),
      findsOneWidget,
    );
    verifyNever(() => cubit.stop());

    await tester
        .tap(find.widgetWithText(FilledButton, 'Interrompi condivisione'));
    await tester.pumpAndSettle();
    verify(() => cubit.stop()).called(1);
  });
}
