import 'package:bookshelf/core/errors/failure.dart';
import 'package:bookshelf/features/search/domain/entities/book.dart';
import 'package:bookshelf/features/shelf_share/data/datasources/shelf_share_remote_data_source.dart';
import 'package:bookshelf/features/shelf_share/data/mappers/shelf_share_mapper.dart';
import 'package:bookshelf/features/shelf_share/data/repositories/shelf_share_repository_impl.dart';
import 'package:bookshelf/features/shelf_share/domain/entities/shelf_share.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockRemote extends Mock implements ShelfShareRemoteDataSource {}

void main() {
  group('ShelfShareMapper', () {
    test('reads the rpc payload', () {
      final shelf = ShelfShareMapper.sharedFromJson(const {
        'shelf_name': 'Letture autunnali',
        'owner_name': null,
        'books': [
          {
            'external_id': 'OL45804W',
            'title': 'Il nome della rosa',
            'authors': ['Umberto Eco'],
            'cover_url': 'https://covers.openlibrary.org/b/id/1-M.jpg',
            'published_year': 1980,
          },
        ],
      });

      expect(shelf.shelfName, 'Letture autunnali');
      expect(shelf.ownerName, isNull);
      expect(shelf.books, const [
        Book(
          externalId: 'OL45804W',
          title: 'Il nome della rosa',
          authors: ['Umberto Eco'],
          coverUrl: 'https://covers.openlibrary.org/b/id/1-M.jpg',
          publishedYear: 1980,
        ),
      ]);
    });

    test('an empty shelf has no books', () {
      final shelf = ShelfShareMapper.sharedFromJson(const {
        'shelf_name': 'Vuoto',
        'owner_name': 'Marco',
        'books': <Object>[],
      });
      expect(shelf.books, isEmpty);
      expect(shelf.ownerName, 'Marco');
    });

    test('reads a share row', () {
      expect(
        ShelfShareMapper.shareFromJson(const {
          'shelf_name': 'Regali',
          'token': 'tok',
        }),
        const ShelfShare(shelfName: 'Regali', token: 'tok'),
      );
    });
  });

  group('SupabaseShelfShareDataSource.matching', () {
    final rows = [
      {'id': '1', 'shelf_name': 'Top', 'token': 'a'},
      {'id': '2', 'shelf_name': 'Top*', 'token': 'b'},
      {'id': '3', 'shelf_name': '100%_x', 'token': 'c'},
    ];

    test('matches the whole name, ignoring case only', () {
      expect(
        SupabaseShelfShareDataSource.matching(rows, 'top*').map((r) => r['id']),
        ['2'],
      );
      expect(
        SupabaseShelfShareDataSource.matching(rows, '*').map((r) => r['id']),
        isEmpty,
      );
      expect(
        SupabaseShelfShareDataSource.matching(rows, '100%_X')
            .map((r) => r['id']),
        ['3'],
      );
    });
  });

  group('ShelfShareRepositoryImpl', () {
    late _MockRemote remote;
    late ShelfShareRepositoryImpl repository;

    setUp(() {
      remote = _MockRemote();
      repository = ShelfShareRepositoryImpl(remote);
    });

    test('fetchShared returns null when the rpc returns null', () async {
      when(() => remote.getShared('gone')).thenAnswer((_) async => null);
      expect(await repository.fetchShared('gone'), isNull);
    });

    test('fetchShared returns null for an empty token', () async {
      expect(await repository.fetchShared('  '), isNull);
      verifyNever(() => remote.getShared(any()));
    });

    test('create rethrows PostgrestException as Failure', () async {
      when(() => remote.insert('Regali')).thenThrow(
        const PostgrestException(message: 'missing', code: 'PGRST205'),
      );
      await expectLater(
        repository.create('Regali'),
        throwsA(
          const Failure(FailureCode.outdatedDatabase, message: 'missing'),
        ),
      );
    });

    test('revoke deletes by shelf name', () async {
      when(() => remote.deleteByShelf('Regali')).thenAnswer((_) async {});
      await repository.revoke('Regali');
      verify(() => remote.deleteByShelf('Regali')).called(1);
    });

    test('shareFor maps the row or returns null', () async {
      when(() => remote.findByShelf('Regali'))
          .thenAnswer((_) async => {'shelf_name': 'Regali', 'token': 't'});
      when(() => remote.findByShelf('Altro')).thenAnswer((_) async => null);
      expect(
        await repository.shareFor('Regali'),
        const ShelfShare(shelfName: 'Regali', token: 't'),
      );
      expect(await repository.shareFor('Altro'), isNull);
    });
  });
}
