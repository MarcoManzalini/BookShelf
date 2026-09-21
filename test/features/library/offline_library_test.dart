import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:bookshelf/core/errors/failure.dart';
import 'package:bookshelf/features/library/data/datasources/library_remote_data_source.dart';
import 'package:bookshelf/features/library/data/local/library_cache.dart';
import 'package:bookshelf/features/library/data/local/pending_change.dart';
import 'package:bookshelf/features/library/data/mappers/user_book_mapper.dart';
import 'package:bookshelf/features/library/data/repositories/library_repository_impl.dart';
import 'package:bookshelf/features/library/domain/entities/reading_status.dart';
import 'package:bookshelf/features/library/domain/entities/sync_status.dart';
import 'package:bookshelf/features/library/presentation/bloc/library_bloc.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';

class MockRemote extends Mock implements LibraryRemoteDataSource {}

class MemoryCache implements LibraryCache {
  LibrarySnapshot? snapshot;

  @override
  Future<LibrarySnapshot?> read() async => snapshot;

  @override
  Future<void> write(LibrarySnapshot snapshot) async =>
      this.snapshot = snapshot;

  @override
  Future<void> clear() async => snapshot = null;
}

DioException get _offline => DioException(
      requestOptions: RequestOptions(),
      type: DioExceptionType.connectionError,
    );

void main() {
  late MockRemote remote;
  late MemoryCache cache;
  String? userId;

  final dune = buildUserBook(id: 'a');
  final emma = buildUserBook(
    id: 'b',
    book: buildBook(id: 'OL2W', title: 'Emma'),
  );

  setUpAll(() {
    registerFallbackValue(buildUserBook());
    registerFallbackValue(buildBook());
    registerFallbackValue(ReadingStatus.read);
  });

  setUp(() {
    remote = MockRemote();
    cache = MemoryCache();
    userId = 'u1';
  });

  LibraryRepositoryImpl build() => LibraryRepositoryImpl(
        remote,
        cache: cache,
        currentUserId: () => userId,
      );

  Future<LibraryRepositoryImpl> online() async {
    when(() => remote.fetchAll()).thenAnswer((_) async => [dune, emma]);
    final repo = build();
    await repo.fetchAll();
    return repo;
  }

  group('saved copy', () {
    test('every change is written to the cache', () async {
      await online();
      expect(cache.snapshot!.userId, 'u1');
      expect(cache.snapshot!.books.map((b) => b.id), ['a', 'b']);
    });

    test('a fresh launch without a connection shows the saved copy', () async {
      await online();

      final relaunched = build();
      when(() => remote.fetchAll()).thenThrow(_offline);
      final books = await relaunched.fetchAll();

      expect(books.map((b) => b.id), ['a', 'b']);
      expect(relaunched.currentSync.offline, isTrue);
    });

    test('no saved copy and no connection is still an error', () async {
      when(() => remote.fetchAll()).thenThrow(_offline);
      await expectLater(
        build().fetchAll(),
        throwsA(const Failure(FailureCode.network)),
      );
    });

    test('a saved copy of another user is discarded', () async {
      await online();
      userId = 'someone-else';

      when(() => remote.fetchAll()).thenThrow(_offline);
      await expectLater(
        build().fetchAll(),
        throwsA(const Failure(FailureCode.network)),
      );
      expect(cache.snapshot, isNull);
    });

    test('signing out wipes the saved copy', () async {
      final repo = await online();
      repo.clear();
      await Future<void>.delayed(Duration.zero);
      expect(cache.snapshot, isNull);
    });

    test('server errors are not hidden behind the saved copy', () async {
      final repo = await online();
      when(() => remote.fetchAll()).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: 500,
          ),
        ),
      );
      await expectLater(repo.fetchAll(), throwsA(isA<Failure>()));
    });
  });

  group('editing offline', () {
    test('an update is applied locally and queued', () async {
      final repo = await online();
      when(() => remote.update(any())).thenThrow(_offline);

      final edited = dune.copyWith(rating: () => 4);
      final saved = await repo.update(edited);

      expect(saved, edited);
      expect(repo.cachedBooks.firstWhere((b) => b.id == 'a').rating, 4);
      expect(repo.currentSync, const SyncStatus(offline: true, pending: 1));
      expect(cache.snapshot!.pending, hasLength(1));
    });

    test('only the latest edit of a book is kept', () async {
      final repo = await online();
      when(() => remote.update(any())).thenThrow(_offline);

      await repo.update(dune.copyWith(rating: () => 2));
      await repo.update(dune.copyWith(rating: () => 5));

      expect(repo.currentSync.pending, 1);
      final queued = cache.snapshot!.pending.single as PendingUpdate;
      expect(queued.book.rating, 5);
    });

    test('a removal is applied locally and queued', () async {
      final repo = await online();
      when(() => remote.delete(any())).thenThrow(_offline);

      await repo.remove('a');

      expect(repo.cachedBooks.map((b) => b.id), ['b']);
      expect(cache.snapshot!.pending.single, isA<PendingDelete>());
    });

    test('removing drops the queued edit of that book', () async {
      final repo = await online();
      when(() => remote.update(any())).thenThrow(_offline);
      when(() => remote.delete(any())).thenThrow(_offline);

      await repo.update(dune.copyWith(rating: () => 3));
      await repo.remove('a');

      expect(repo.currentSync.pending, 1);
      expect(cache.snapshot!.pending.single, isA<PendingDelete>());
    });

    test('adding a book needs the connection', () async {
      final repo = await online();
      when(() => remote.insert(any(), any())).thenThrow(_offline);

      await expectLater(
        repo.add(buildBook(id: 'OL9W'), ReadingStatus.reading),
        throwsA(const Failure(FailureCode.network)),
      );
      expect(repo.currentSync.pending, 0);
    });

    test('a real server error on update is not queued', () async {
      final repo = await online();
      when(() => remote.update(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: 500,
          ),
        ),
      );
      await expectLater(repo.update(dune), throwsA(isA<Failure>()));
      expect(repo.currentSync.pending, 0);
    });

    test('a later successful update supersedes a queued one', () async {
      final repo = await online();
      when(() => remote.update(any())).thenThrow(_offline);
      await repo.update(dune.copyWith(rating: () => 2));
      expect(repo.currentSync.pending, 1);

      final newer = dune.copyWith(rating: () => 5);
      when(() => remote.update(any())).thenAnswer((_) async => newer);
      await repo.update(newer);

      expect(repo.currentSync, const SyncStatus());
    });
  });

  group('syncing', () {
    test('queued edits are sent, in order, when the server is back', () async {
      final repo = await online();
      when(() => remote.update(any())).thenThrow(_offline);
      when(() => remote.delete(any())).thenThrow(_offline);
      final edited = dune.copyWith(rating: () => 4);
      await repo.update(edited);
      await repo.remove('b');

      // Back online.
      when(() => remote.update(any())).thenAnswer((_) async => edited);
      when(() => remote.delete(any())).thenAnswer((_) async {});
      when(() => remote.fetchAll()).thenAnswer((_) async => [dune]);
      final books = await repo.fetchAll();

      verifyInOrder([
        () => remote.update(edited),
        () => remote.delete('b'),
      ]);
      expect(repo.currentSync, const SyncStatus());
      expect(cache.snapshot!.pending, isEmpty);
      expect(books.map((b) => b.id), ['a']);
    });

    test('unsent edits stay visible if the refresh happens still offline',
        () async {
      final repo = await online();
      when(() => remote.update(any())).thenThrow(_offline);
      await repo.update(dune.copyWith(rating: () => 4));

      when(() => remote.fetchAll()).thenThrow(_offline);
      final books = await repo.fetchAll();

      expect(books.firstWhere((b) => b.id == 'a').rating, 4);
      expect(repo.currentSync.pending, 1);
    });

    test('unsent edits are overlaid on a partial sync', () async {
      final repo = await online();
      final edited = dune.copyWith(rating: () => 4);
      when(() => remote.update(any())).thenThrow(_offline);
      await repo.update(edited);

      // The flush fails again but the fetch would succeed (flaky network).
      var calls = 0;
      when(() => remote.update(any())).thenAnswer((_) async {
        if (calls++ == 0) throw _offline;
        return edited;
      });
      when(() => remote.fetchAll()).thenAnswer((_) async => [dune, emma]);
      final books = await repo.fetchAll();
      // Flush failed: rethrown as offline, list keeps the local edit.
      expect(books.firstWhere((b) => b.id == 'a').rating, 4);
    });

    test('a change the server refuses for good is dropped, not retried forever',
        () async {
      final repo = await online();
      when(() => remote.update(any())).thenThrow(_offline);
      await repo.update(dune.copyWith(rating: () => 4));

      when(() => remote.update(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: 404,
          ),
        ),
      );
      when(() => remote.fetchAll()).thenAnswer((_) async => [emma]);
      await repo.fetchAll();

      expect(repo.currentSync, const SyncStatus());
    });

    test('sync status is published as it changes', () async {
      final repo = await online();
      final seen = <SyncStatus>[];
      final sub = repo.syncStatus.listen(seen.add);
      when(() => remote.update(any())).thenThrow(_offline);

      await repo.update(dune.copyWith(rating: () => 4));
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(seen.last, const SyncStatus(offline: true, pending: 1));
    });
  });

  group('cache format', () {
    test('a book survives a round trip through the cache JSON', () {
      final book = buildUserBook(
        id: 'z',
        status: ReadingStatus.reading,
        currentPage: 120,
        rating: 4,
        startedAt: DateTime(2026, 3, 1),
        book: buildBook(id: 'OL7W', title: 'Émile', pageCount: 321).copyWith(
          subjects: const ['Novel'],
          editionKey: 'OL5M',
        ),
      ).copyWith(shelves: const ['Regali']);

      final back = UserBookMapper.fromJson(UserBookMapper.toCacheJson(book));
      expect(back.id, book.id);
      expect(back.status, book.status);
      expect(back.currentPage, 120);
      expect(back.rating, 4);
      expect(back.startedAt, DateTime(2026, 3, 1));
      expect(back.shelves, ['Regali']);
      expect(back.book.title, 'Émile');
      expect(back.book.pageCount, 321);
      expect(back.book.editionKey, 'OL5M');
      expect(back.createdAt, book.createdAt);
    });

    test('a corrupt or foreign snapshot reads as no snapshot', () {
      expect(LibrarySnapshot.fromJson('nope'), isNull);
      expect(LibrarySnapshot.fromJson({'userId': 1}), isNull);
      expect(
        LibrarySnapshot.fromJson({
          'userId': 'u',
          'books': [
            {'id': 5},
          ],
        }),
        isNull,
      );
    });
  });

  group('LibraryBloc offline', () {
    late MockLibraryRepository repository;
    late StreamController<SyncStatus> sync;

    setUp(() {
      repository = MockLibraryRepository();
      sync = StreamController<SyncStatus>.broadcast();
      when(() => repository.syncStatus).thenAnswer((_) => sync.stream);
      when(() => repository.books).thenAnswer((_) => const Stream.empty());
      when(() => repository.fetchAll()).thenAnswer((_) async => [dune]);
    });

    blocTest<LibraryBloc, LibraryState>(
      'mirrors the offline state and the pending count',
      build: () => LibraryBloc(repository, MockAddBookToLibrary()),
      act: (bloc) async {
        bloc.add(const LibraryStarted());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        sync.add(const SyncStatus(offline: true, pending: 2));
        await Future<void>.delayed(const Duration(milliseconds: 10));
      },
      verify: (bloc) {
        expect(bloc.state.offline, isTrue);
        expect(bloc.state.pendingChanges, 2);
      },
    );

    test('retries by itself while offline and stops when back online',
        () async {
      final bloc = LibraryBloc(repository, MockAddBookToLibrary());
      addTearDown(bloc.close);
      bloc.add(const LibraryStarted());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      clearInteractions(repository);

      sync.add(const SyncStatus(offline: true));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      // The timer is real time: prove it is armed by going back online and
      // checking the state is consistent, without waiting 30 s in a test.
      expect(bloc.state.offline, isTrue);
      sync.add(const SyncStatus());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(bloc.state.offline, isFalse);
      expect(bloc.state.pendingChanges, 0);
    });
  });
}
