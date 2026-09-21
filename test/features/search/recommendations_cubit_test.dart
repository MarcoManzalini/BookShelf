import 'dart:async';

import 'package:bookshelf/core/utils/request_status.dart';
import 'package:bookshelf/features/library/domain/entities/reading_status.dart';
import 'package:bookshelf/features/library/domain/entities/user_book.dart';
import 'package:bookshelf/features/search/domain/entities/book.dart';
import 'package:bookshelf/features/search/presentation/bloc/recommendations_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';

Book _book(
  String id, {
  List<String> subjects = const ['Fantasy'],
  bool cover = true,
}) =>
    Book(
      externalId: id,
      title: id,
      subjects: subjects,
      coverUrl: cover ? 'https://covers.openlibrary.org/b/id/1-L.jpg' : null,
    );

UserBook _read(
  String id,
  DateTime finished, {
  List<String> subjects = const ['Fantasy'],
}) =>
    buildUserBook(
      id: id,
      book: _book(id, subjects: subjects),
      status: ReadingStatus.read,
      finishedAt: finished,
    );

void main() {
  late MockBookSearchRepository search;
  late MockLibraryRepository library;
  late StreamController<List<UserBook>> stream;

  setUpAll(() => registerFallbackValue(_book('x')));

  setUp(() {
    search = MockBookSearchRepository();
    library = MockLibraryRepository();
    stream = StreamController<List<UserBook>>.broadcast();
    when(() => library.books).thenAnswer((_) => stream.stream);
    when(() => library.findCachedByExternalId(any())).thenReturn(null);
  });

  tearDown(() => stream.close());

  group('seedsOf', () {
    test('takes the last three finished books, newest first', () {
      final seeds = RecommendationsCubit.seedsOf([
        _read('old', DateTime(2020)),
        _read('newest', DateTime(2026, 5)),
        _read('mid', DateTime(2025)),
        _read('older', DateTime(2021)),
        buildUserBook(id: 'reading', status: ReadingStatus.reading),
        buildUserBook(id: 'want'),
      ]);

      expect(seeds.map((s) => s.id), ['newest', 'mid', 'older']);
    });

    test('skips books without subjects', () {
      final seeds = RecommendationsCubit.seedsOf([
        _read('bare', DateTime(2026), subjects: const []),
        _read('ok', DateTime(2025)),
      ]);

      expect(seeds.map((s) => s.id), ['ok']);
    });
  });

  group('merge', () {
    List<String> ids(List<Book> books) => [for (final b in books) b.externalId];

    test('interleaves the lists so every source weighs the same', () {
      final merged = RecommendationsCubit.merge(
        [
          [_book('a1'), _book('a2'), _book('a3')],
          [_book('b1'), _book('b2')],
          [_book('c1')],
        ],
        limit: 10,
      );

      expect(ids(merged), ['a1', 'b1', 'c1', 'a2', 'b2', 'a3']);
    });

    test('a book suggested by several sources moves ahead, shown once', () {
      final merged = RecommendationsCubit.merge(
        [
          [_book('a1'), _book('shared')],
          [_book('b1'), _book('shared')],
        ],
        limit: 10,
      );

      expect(ids(merged), ['shared', 'a1', 'b1']);
    });

    test('respects the limit', () {
      final merged = RecommendationsCubit.merge(
        [
          [for (var i = 0; i < 30; i++) _book('a$i')],
        ],
        limit: 20,
      );

      expect(merged, hasLength(20));
    });
  });

  test('one merged list from the last reads, without library books', () async {
    final dune = _read('dune', DateTime(2026, 2));
    final emma = _read('emma', DateTime(2026, 1));
    when(() => library.cachedBooks).thenReturn([dune, emma]);
    when(() => library.findCachedByExternalId('owned'))
        .thenReturn(buildUserBook(id: 'owned-ub'));
    when(() => search.getSimilarBooks(dune.book)).thenAnswer(
      (_) async => [_book('a'), _book('owned'), _book('nocover', cover: false)],
    );
    when(() => search.getSimilarBooks(emma.book)).thenAnswer(
      (_) async => [_book('a'), _book('b')],
    );
    final cubit = RecommendationsCubit(search, library);

    await cubit.load();

    expect(cubit.state.status, RequestStatus.success);
    // "a" comes from both reads, so it leads; the owned and cover-less books
    // never make it.
    expect(cubit.state.books.map((b) => b.externalId), ['a', 'b']);
    await cubit.close();
  });

  test('nothing finished yet: no shelves and no requests', () async {
    when(() => library.cachedBooks).thenReturn([buildUserBook()]);
    final cubit = RecommendationsCubit(search, library);

    await cubit.load();

    expect(cubit.state.books, isEmpty);
    expect(cubit.state.status, RequestStatus.success);
    verifyNever(() => search.getSimilarBooks(any()));
    await cubit.close();
  });
}
