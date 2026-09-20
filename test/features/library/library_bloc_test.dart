import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:bookshelf/core/errors/failure.dart';
import 'package:bookshelf/core/utils/request_status.dart';
import 'package:bookshelf/features/library/domain/entities/reading_status.dart';
import 'package:bookshelf/features/library/domain/entities/user_book.dart';
import 'package:bookshelf/features/library/presentation/bloc/library_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';

void main() {
  late MockLibraryRepository repository;
  late MockAddBookToLibrary addBook;
  late StreamController<List<UserBook>> changes;

  final reading = buildUserBook(
    id: 'a',
    book: buildBook(id: 'OL1W'),
    status: ReadingStatus.reading,
  );
  final read = buildUserBook(
    id: 'b',
    book: buildBook(id: 'OL2W', title: 'Emma'),
    status: ReadingStatus.read,
  );

  setUpAll(() {
    registerFallbackValue(buildBook());
    registerFallbackValue(ReadingStatus.read);
  });

  setUp(() {
    repository = MockLibraryRepository();
    addBook = MockAddBookToLibrary();
    changes = StreamController<List<UserBook>>.broadcast();
    when(() => repository.books).thenAnswer((_) => changes.stream);
  });

  tearDown(() => changes.close());

  LibraryBloc build() => LibraryBloc(repository, addBook);

  group('LibraryStarted', () {
    blocTest<LibraryBloc, LibraryState>(
      'loads books: loading -> success',
      setUp: () =>
          when(() => repository.fetchAll()).thenAnswer((_) async => [reading]),
      build: build,
      act: (bloc) => bloc.add(const LibraryStarted()),
      expect: () => [
        const LibraryState(status: RequestStatus.loading),
        LibraryState(status: RequestStatus.success, books: [reading]),
      ],
    );

    blocTest<LibraryBloc, LibraryState>(
      'emits failure when loading fails',
      setUp: () => when(() => repository.fetchAll())
          .thenThrow(const Failure(FailureCode.network)),
      build: build,
      act: (bloc) => bloc.add(const LibraryStarted()),
      expect: () => [
        const LibraryState(status: RequestStatus.loading),
        const LibraryState(
          status: RequestStatus.failure,
          failure: Failure(FailureCode.network),
        ),
      ],
    );

    blocTest<LibraryBloc, LibraryState>(
      'follows repository changes (edits from the details page)',
      setUp: () =>
          when(() => repository.fetchAll()).thenAnswer((_) async => [reading]),
      build: build,
      act: (bloc) async {
        bloc.add(const LibraryStarted());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        changes.add([reading, read]);
      },
      skip: 2,
      expect: () => [
        LibraryState(status: RequestStatus.success, books: [reading, read]),
      ],
    );
  });

  group('filter and view mode', () {
    blocTest<LibraryBloc, LibraryState>(
      'filters visible books by status',
      build: build,
      seed: () => LibraryState(
        status: RequestStatus.success,
        books: [reading, read],
      ),
      act: (bloc) => bloc.add(const LibraryFilterChanged(LibraryFilter.read)),
      expect: () => [
        isA<LibraryState>()
            .having((s) => s.filter, 'filter', LibraryFilter.read)
            .having((s) => s.visibleBooks, 'visibleBooks', [read]),
      ],
    );

    blocTest<LibraryBloc, LibraryState>(
      'toggles list/grid',
      build: build,
      act: (bloc) => bloc
        ..add(const LibraryViewModeToggled())
        ..add(const LibraryViewModeToggled()),
      expect: () => const [
        LibraryState(viewMode: LibraryViewMode.grid),
        LibraryState(viewMode: LibraryViewMode.list),
      ],
    );
  });

  group('LibraryBookAdded', () {
    final book = buildBook(id: 'OL9W', title: 'New');

    blocTest<LibraryBloc, LibraryState>(
      'tracks the adding id and calls the use case',
      setUp: () => when(() => addBook(any(), any()))
          .thenAnswer((_) async => buildUserBook(book: book)),
      build: build,
      act: (bloc) => bloc.add(LibraryBookAdded(book, ReadingStatus.wantToRead)),
      expect: () => const [
        LibraryState(addingIds: {'OL9W'}),
        LibraryState(),
      ],
      verify: (_) =>
          verify(() => addBook(book, ReadingStatus.wantToRead)).called(1),
    );

    blocTest<LibraryBloc, LibraryState>(
      'reports actionFailure when adding fails',
      setUp: () => when(() => addBook(any(), any()))
          .thenThrow(const Failure(FailureCode.server)),
      build: build,
      act: (bloc) => bloc.add(LibraryBookAdded(book, ReadingStatus.read)),
      expect: () => const [
        LibraryState(addingIds: {'OL9W'}),
        LibraryState(actionFailure: Failure(FailureCode.server)),
      ],
    );

    blocTest<LibraryBloc, LibraryState>(
      'ignores a book that is already in the library',
      build: build,
      seed: () => LibraryState(books: [reading]),
      act: (bloc) => bloc.add(
        LibraryBookAdded(reading.book, ReadingStatus.read),
      ),
      expect: () => const <LibraryState>[],
      verify: (_) => verifyNever(() => addBook(any(), any())),
    );
  });

  group('LibraryRefreshRequested', () {
    blocTest<LibraryBloc, LibraryState>(
      'refreshes and updates books',
      setUp: () => when(() => repository.fetchAll())
          .thenAnswer((_) async => [reading, read]),
      build: build,
      act: (bloc) => bloc.add(const LibraryRefreshRequested()),
      expect: () => [
        const LibraryState(refreshing: true),
        LibraryState(status: RequestStatus.success, books: [reading, read]),
      ],
    );

    blocTest<LibraryBloc, LibraryState>(
      'keeps the current list and reports actionFailure when offline',
      setUp: () => when(() => repository.fetchAll())
          .thenThrow(const Failure(FailureCode.network)),
      build: build,
      seed: () => LibraryState(status: RequestStatus.success, books: [reading]),
      act: (bloc) => bloc.add(const LibraryRefreshRequested()),
      expect: () => [
        LibraryState(
          status: RequestStatus.success,
          books: [reading],
          refreshing: true,
        ),
        LibraryState(
          status: RequestStatus.success,
          books: [reading],
          actionFailure: const Failure(FailureCode.network),
        ),
      ],
    );
  });

  blocTest<LibraryBloc, LibraryState>(
    'LibraryCleared resets state and the repository cache',
    setUp: () => when(() => repository.clear()).thenReturn(null),
    build: build,
    seed: () => LibraryState(status: RequestStatus.success, books: [reading]),
    act: (bloc) => bloc.add(const LibraryCleared()),
    expect: () => const [LibraryState()],
    verify: (_) => verify(() => repository.clear()).called(1),
  );

  test('containsExternalId matches the Open Library id', () {
    final state = LibraryState(books: [reading]);
    expect(state.containsExternalId('OL1W'), isTrue);
    expect(state.containsExternalId('OL404W'), isFalse);
  });
}
