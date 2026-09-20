import 'package:bookshelf/core/errors/failure.dart';
import 'package:bookshelf/features/library/data/datasources/library_remote_data_source.dart';
import 'package:bookshelf/features/library/data/repositories/library_repository_impl.dart';
import 'package:bookshelf/features/library/domain/entities/reading_status.dart';
import 'package:bookshelf/features/library/domain/entities/user_book.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures.dart';

class MockRemote extends Mock implements LibraryRemoteDataSource {}

void main() {
  late MockRemote remote;
  late LibraryRepositoryImpl repository;

  final first = buildUserBook(id: 'a', book: buildBook(id: 'OL1W'));
  final second = buildUserBook(id: 'b', book: buildBook(id: 'OL2W'));

  setUpAll(() {
    registerFallbackValue(buildBook());
    registerFallbackValue(ReadingStatus.read);
    registerFallbackValue(first);
  });

  setUp(() {
    remote = MockRemote();
    repository = LibraryRepositoryImpl(remote);
  });

  test('fetchAll fills the cache and emits', () async {
    when(() => remote.fetchAll()).thenAnswer((_) async => [first, second]);
    final emitted = expectLater(
      repository.books,
      emits([first, second]),
    );

    await repository.fetchAll();

    await emitted;
    expect(repository.cachedBooks, [first, second]);
    expect(repository.findCachedByExternalId('OL2W'), second);
    expect(repository.findCachedByExternalId('nope'), isNull);
  });

  test('add prepends the new book and emits', () async {
    when(() => remote.fetchAll()).thenAnswer((_) async => [first]);
    when(() => remote.insert(any(), any())).thenAnswer((_) async => second);
    await repository.fetchAll();

    final emitted = expectLater(repository.books, emits([second, first]));
    await repository.add(second.book, ReadingStatus.read);
    await emitted;
  });

  test('add returns the existing entry without a second insert', () async {
    when(() => remote.fetchAll()).thenAnswer((_) async => [first]);
    await repository.fetchAll();

    final result = await repository.add(first.book, ReadingStatus.read);

    expect(result, first);
    verifyNever(() => remote.insert(any(), any()));
  });

  test('update replaces the entry in place', () async {
    final rated = first.copyWith(rating: () => 5);
    when(() => remote.fetchAll()).thenAnswer((_) async => [first, second]);
    when(() => remote.update(any())).thenAnswer((_) async => rated);
    await repository.fetchAll();

    await repository.update(rated);

    expect(repository.cachedBooks, [rated, second]);
  });

  test('remove drops the entry', () async {
    when(() => remote.fetchAll()).thenAnswer((_) async => [first, second]);
    when(() => remote.delete('a')).thenAnswer((_) async {});
    await repository.fetchAll();

    await repository.remove('a');

    expect(repository.cachedBooks, [second]);
  });

  test('errors are mapped to Failure and the cache is untouched', () async {
    when(() => remote.fetchAll()).thenAnswer((_) async => [first]);
    when(() => remote.delete(any())).thenThrow(Exception('boom'));
    await repository.fetchAll();

    await expectLater(
      repository.remove('a'),
      throwsA(
        isA<Failure>().having((f) => f.code, 'code', FailureCode.unknown),
      ),
    );
    expect(repository.cachedBooks, [first]);
  });

  test('getById prefers the cache', () async {
    when(() => remote.fetchAll()).thenAnswer((_) async => [first]);
    await repository.fetchAll();

    expect(await repository.getById('a'), first);
    verifyNever(() => remote.fetchById(any()));
  });

  test('clear empties the cache', () async {
    when(() => remote.fetchAll()).thenAnswer((_) async => [first]);
    await repository.fetchAll();
    repository.clear();
    expect(repository.cachedBooks, isEmpty);
  });

  test('UserBook list is unmodifiable', () async {
    when(() => remote.fetchAll()).thenAnswer((_) async => [first]);
    await repository.fetchAll();
    expect(() => repository.cachedBooks.add(second), throwsUnsupportedError);
    expect(repository.cachedBooks, isA<List<UserBook>>());
  });
}
