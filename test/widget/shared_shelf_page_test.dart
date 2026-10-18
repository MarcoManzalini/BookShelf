import 'package:bloc_test/bloc_test.dart';
import 'package:bookshelf/core/utils/request_status.dart';
import 'package:bookshelf/features/library/presentation/bloc/library_bloc.dart';
import 'package:bookshelf/features/shelf_share/domain/entities/shared_shelf.dart';
import 'package:bookshelf/features/shelf_share/presentation/cubit/shared_shelf_cubit.dart';
import 'package:bookshelf/features/shelf_share/presentation/pages/shared_shelf_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_app.dart';

class MockLibraryBloc extends MockBloc<LibraryEvent, LibraryState>
    implements LibraryBloc {}

class MockSharedShelfCubit extends MockCubit<SharedShelfState>
    implements SharedShelfCubit {}

void main() {
  late MockSharedShelfCubit cubit;

  final shelf = SharedShelf(
    shelfName: 'Letture autunnali',
    ownerName: 'Marco',
    books: [buildBook(), buildBook(id: 'OL2W', title: 'Emma')],
  );

  setUp(() => cubit = MockSharedShelfCubit());

  Future<void> pump(WidgetTester tester, SharedShelfState state) {
    when(() => cubit.state).thenReturn(state);
    final library = MockLibraryBloc();
    whenListen(
      library,
      const Stream<LibraryState>.empty(),
      initialState: const LibraryState(),
    );
    return tester.pumpApp(
      MultiBlocProvider(
        providers: [
          BlocProvider<LibraryBloc>.value(value: library),
          BlocProvider<SharedShelfCubit>.value(value: cubit),
        ],
        child: const SharedShelfView(),
      ),
    );
  }

  testWidgets('shows title, owner and books', (tester) async {
    await pump(
      tester,
      SharedShelfState(status: RequestStatus.success, shelf: shelf),
    );

    expect(find.text('Letture autunnali'), findsOneWidget);
    expect(find.text('Uno scaffale di Marco · 2 libri'), findsOneWidget);
    expect(find.text('Dune'), findsWidgets);
    expect(find.text('Emma'), findsWidgets);
  });

  testWidgets('offers a way to the library when opened from a link',
      (tester) async {
    await pump(
      tester,
      SharedShelfState(status: RequestStatus.success, shelf: shelf),
    );

    expect(find.byTooltip('Vai alla libreria'), findsOneWidget);
  });

  testWidgets('shows not found message', (tester) async {
    await pump(
      tester,
      const SharedShelfState(status: RequestStatus.success, notFound: true),
    );

    expect(find.text('Questo scaffale non è più condiviso'), findsOneWidget);
    expect(find.text('Salva nella mia libreria'), findsNothing);
  });

  testWidgets('tapping save calls saveToLibrary', (tester) async {
    when(() => cubit.saveToLibrary()).thenAnswer((_) async {});
    await pump(
      tester,
      SharedShelfState(status: RequestStatus.success, shelf: shelf),
    );

    await tester.tap(find.text('Salva nella mia libreria'));
    verify(() => cubit.saveToLibrary()).called(1);
  });
}
