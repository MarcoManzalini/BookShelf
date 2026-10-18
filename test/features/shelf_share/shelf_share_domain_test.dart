import 'package:bookshelf/features/library/domain/entities/reading_status.dart';
import 'package:bookshelf/features/library/domain/entities/shelf_names.dart';
import 'package:bookshelf/features/library/domain/entities/user_book.dart';
import 'package:bookshelf/features/search/domain/entities/book.dart';
import 'package:bookshelf/features/shelf_share/domain/entities/shared_shelf.dart';
import 'package:bookshelf/features/shelf_share/domain/entities/shelf_share.dart';
import 'package:bookshelf/features/shelf_share/domain/usecases/save_shared_shelf.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';

const _shelf = 'Letture autunnali';

UserBook _owned(String id, List<String> shelves) => buildUserBook(
      id: 'ub-$id',
      book: buildBook(id: id, title: id),
    ).copyWith(shelves: shelves);

void main() {
  group('ShelfShare', () {
    test('webUrl and appUrl carry the token', () {
      const share = ShelfShare(shelfName: _shelf, token: 'abc_-123');
      expect(
        share.webUrl.toString(),
        'https://marcomanzalini.github.io/BookShelf/s/?t=abc_-123',
      );
      expect(
        share.appUrl.toString(),
        'io.supabase.bookshelf://shelf/shared-shelf/abc_-123',
      );
    });
  });

  group('SaveSharedShelf', () {
    late MockLibraryRepository library;
    late SaveSharedShelf save;

    final dune = buildBook(id: 'OL1W', title: 'Dune');
    final emma = buildBook(id: 'OL2W', title: 'Emma');

    SharedShelf shelfOf(List<Book> books) =>
        SharedShelf(shelfName: _shelf, ownerName: 'Marco', books: books);

    setUpAll(() {
      registerFallbackValue(buildBook());
      registerFallbackValue(ReadingStatus.read);
      registerFallbackValue(buildUserBook());
    });

    setUp(() {
      library = MockLibraryRepository();
      save = SaveSharedShelf(library);
      when(() => library.cachedBooks).thenReturn(const []);
      when(() => library.fetchAll()).thenAnswer((_) async => const []);
      when(() => library.findCachedByExternalId(any())).thenReturn(null);
      when(() => library.update(any()))
          .thenAnswer((i) async => i.positionalArguments.first as UserBook);
      when(() => library.add(any(), any())).thenAnswer(
        (i) async => buildUserBook(
          id: 'new-${(i.positionalArguments.first as Book).externalId}',
          book: i.positionalArguments.first as Book,
        ),
      );
    });

    test('adds missing books as wantToRead with the shelf tag', () async {
      final added = await save(shelfOf([dune, emma]));

      expect(added, 2);
      verify(() => library.add(dune, ReadingStatus.wantToRead)).called(1);
      verify(() => library.add(emma, ReadingStatus.wantToRead)).called(1);
      final updated = verify(() => library.update(captureAny())).captured;
      expect(
        updated.cast<UserBook>().map((b) => b.shelves),
        everyElement([_shelf]),
      );
    });

    test('loads the library first when the cache is empty', () async {
      await save(shelfOf([dune]));
      verifyInOrder([
        () => library.fetchAll(),
        () => library.findCachedByExternalId('OL1W'),
      ]);
    });

    test('does not reload a library already in memory', () async {
      when(() => library.cachedBooks).thenReturn([
        _owned('OL9W', ['X']),
      ]);
      await save(shelfOf([dune]));
      verifyNever(() => library.fetchAll());
    });

    test('only tags books already in the library', () async {
      final mine = _owned('OL1W', ['Preferiti']);
      when(() => library.findCachedByExternalId('OL1W')).thenReturn(mine);

      final added = await save(shelfOf([dune]));

      expect(added, 0);
      verifyNever(() => library.add(any(), any()));
      final updated =
          verify(() => library.update(captureAny())).captured.single;
      expect((updated as UserBook).shelves, ['Preferiti', _shelf]);
    });

    test('does nothing for books already on the shelf', () async {
      final mine = _owned('OL1W', ['letture autunnali']);
      when(() => library.cachedBooks).thenReturn([mine]);
      when(() => library.findCachedByExternalId('OL1W')).thenReturn(mine);

      final added = await save(shelfOf([dune]));

      expect(added, 0);
      verifyNever(() => library.add(any(), any()));
      verifyNever(() => library.update(any()));
    });

    test("reuses the reader's spelling of an existing shelf", () async {
      when(() => library.cachedBooks).thenReturn([
        _owned('OL9W', ['letture AUTUNNALI']),
      ]);

      await save(shelfOf([dune]));

      final updated =
          verify(() => library.update(captureAny())).captured.single;
      expect((updated as UserBook).shelves, ['letture AUTUNNALI']);
    });

    test('skips books already on maxPerBook shelves', () async {
      final full = _owned(
        'OL1W',
        [for (var i = 0; i < ShelfNames.maxPerBook; i++) 'S$i'],
      );
      when(() => library.findCachedByExternalId('OL1W')).thenReturn(full);

      final added = await save(shelfOf([dune]));

      expect(added, 0);
      verifyNever(() => library.update(any()));
    });
  });
}
