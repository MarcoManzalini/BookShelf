import 'package:bloc_test/bloc_test.dart';
import 'package:bookshelf/core/utils/request_status.dart';
import 'package:bookshelf/features/book_details/presentation/bloc/book_details_bloc.dart';
import 'package:bookshelf/features/library/data/mappers/user_book_mapper.dart';
import 'package:bookshelf/features/library/domain/entities/shelf_names.dart';
import 'package:bookshelf/features/library/domain/entities/user_book.dart';
import 'package:bookshelf/features/library/presentation/bloc/library_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';

UserBook onShelves(String id, List<String> shelves) => buildUserBook(
      id: id,
      book: buildBook(id: 'OL${id}W', title: id),
    ).copyWith(shelves: shelves);

void main() {
  group('ShelfNames', () {
    test('normalizes whitespace and rejects blanks', () {
      expect(ShelfNames.normalize('  Sci   Fi '), 'Sci Fi');
      expect(ShelfNames.normalize('   '), isNull);
    });

    test('caps the name length', () {
      final name = ShelfNames.normalize('x' * 80)!;
      expect(name.length, ShelfNames.maxLength);
    });

    test('clean drops case-insensitive duplicates keeping the first spelling',
        () {
      expect(
        ShelfNames.clean(['Regali', 'regali', ' REGALI ', 'Estate', '']),
        ['Regali', 'Estate'],
      );
    });

    test('clean caps the number of shelves per book', () {
      final many = [for (var i = 0; i < 40; i++) 'Shelf $i'];
      expect(ShelfNames.clean(many), hasLength(ShelfNames.maxPerBook));
    });
  });

  group('LibraryState shelves', () {
    final state = LibraryState(
      status: RequestStatus.success,
      books: [
        onShelves('a', ['Regali', 'Estate']),
        onShelves('b', ['regali']),
        onShelves('c', const []),
      ],
    );

    test('counts books per shelf, merging spellings', () {
      expect(state.shelfCounts, {'Estate': 1, 'Regali': 2});
    });

    test('narrows the visible books to a shelf, ignoring case', () {
      final narrowed = state.copyWith(shelfFilter: () => 'REGALI');
      expect(narrowed.visibleBooks.map((b) => b.id), ['a', 'b']);
      expect(narrowed.hasActiveFilter, isTrue);
    });

    test('combines the shelf with the status filter', () {
      final narrowed = state.copyWith(
        shelfFilter: () => 'Regali',
        filter: LibraryFilter.reading,
      );
      expect(narrowed.visibleBooks, isEmpty);
    });
  });

  group('LibraryBloc', () {
    late MockLibraryRepository repository;
    late MockAddBookToLibrary addBook;

    setUp(() {
      repository = MockLibraryRepository();
      addBook = MockAddBookToLibrary();
    });

    blocTest<LibraryBloc, LibraryState>(
      'sets and clears the shelf filter',
      build: () => LibraryBloc(repository, addBook),
      act: (bloc) => bloc
        ..add(const LibraryShelfFilterChanged('Regali'))
        ..add(const LibraryShelfFilterChanged(null)),
      expect: () => [
        const LibraryState(shelfFilter: 'Regali'),
        const LibraryState(),
      ],
    );
  });

  group('persistence', () {
    test('shelves are written on update and read back', () {
      final book = onShelves('a', ['Regali', 'Estate']);
      final json = UserBookMapper.toUpdateJson(book);
      expect(json['shelves'], ['Regali', 'Estate']);

      final read = UserBookMapper.fromJson({
        'id': 'a',
        'external_id': 'OLaW',
        'title': 'a',
        'status': 'reading',
        'created_at': '2024-01-01T00:00:00Z',
        'shelves': ['Regali'],
      });
      expect(read.shelves, ['Regali']);
    });

    test('a row without the column (old database) has no shelves', () {
      final read = UserBookMapper.fromJson({
        'id': 'a',
        'external_id': 'OLaW',
        'title': 'a',
        'status': 'reading',
        'created_at': '2024-01-01T00:00:00Z',
      });
      expect(read.shelves, isEmpty);
    });
  });

  group('BookDetailsBloc shelves', () {
    late MockLibraryRepository library;
    late MockBookSearchRepository search;
    late MockAddBookToLibrary addBook;
    late MockReadingLogRepository logs;
    final saved = buildUserBook();

    setUpAll(() => registerFallbackValue(buildUserBook()));

    setUp(() {
      library = MockLibraryRepository();
      search = MockBookSearchRepository();
      addBook = MockAddBookToLibrary();
      logs = MockReadingLogRepository();
      when(() => logs.forBook(any())).thenAnswer((_) async => []);
    });

    blocTest<BookDetailsBloc, BookDetailsState>(
      'saves cleaned shelves on the saved book',
      setUp: () => when(() => library.update(any()))
          .thenAnswer((i) async => i.positionalArguments.first as UserBook),
      build: () => BookDetailsBloc(
        libraryRepository: library,
        searchRepository: search,
        addBook: addBook,
        readingLogs: logs,
      ),
      seed: () => BookDetailsState(
        status: RequestStatus.success,
        book: saved.book,
        userBook: saved,
      ),
      act: (bloc) => bloc
          .add(const BookDetailsShelvesChanged(['Regali', 'regali', ' ', 'X'])),
      verify: (bloc) {
        expect(bloc.state.userBook!.shelves, ['Regali', 'X']);
        final saved = verify(() => library.update(captureAny())).captured.single
            as UserBook;
        expect(saved.shelves, ['Regali', 'X']);
      },
    );
  });
}
