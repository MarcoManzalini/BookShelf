import 'package:bloc_test/bloc_test.dart';
import 'package:bookshelf/core/errors/failure.dart';
import 'package:bookshelf/core/utils/request_status.dart';
import 'package:bookshelf/features/search/domain/entities/book_search_page.dart';
import 'package:bookshelf/features/search/presentation/bloc/search_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';

void main() {
  late MockBookSearchRepository repository;

  final dune = buildBook(id: 'OL1W');
  final emma = buildBook(id: 'OL2W', title: 'Emma');
  const debounce = Duration(milliseconds: 20);
  const settle = Duration(milliseconds: 120);

  setUp(() => repository = MockBookSearchRepository());

  SearchBloc build() => SearchBloc(repository, debounce: debounce);

  blocTest<SearchBloc, SearchState>(
    'emits loading then results',
    setUp: () => when(() => repository.search('dune')).thenAnswer(
      (_) async => BookSearchPage(books: [dune], page: 1, hasMore: true),
    ),
    build: build,
    act: (bloc) => bloc.add(const SearchQueryChanged('dune')),
    wait: settle,
    expect: () => [
      const SearchState(query: 'dune', status: RequestStatus.loading),
      SearchState(
        query: 'dune',
        status: RequestStatus.success,
        books: [dune],
        page: 1,
        hasMore: true,
      ),
    ],
  );

  blocTest<SearchBloc, SearchState>(
    'debounces rapid typing into a single request',
    setUp: () => when(() => repository.search(any())).thenAnswer(
      (_) async => BookSearchPage(books: [dune], page: 1, hasMore: false),
    ),
    build: build,
    act: (bloc) async {
      bloc.add(const SearchQueryChanged('d'));
      bloc.add(const SearchQueryChanged('du'));
      bloc.add(const SearchQueryChanged('dun'));
    },
    wait: settle,
    verify: (_) {
      verify(() => repository.search('dun')).called(1);
      verifyNever(() => repository.search('d'));
      verifyNever(() => repository.search('du'));
    },
  );

  blocTest<SearchBloc, SearchState>(
    'emits an empty success state when nothing is found',
    setUp: () => when(() => repository.search('zzzz')).thenAnswer(
      (_) async => const BookSearchPage(books: [], page: 1, hasMore: false),
    ),
    build: build,
    act: (bloc) => bloc.add(const SearchQueryChanged('zzzz')),
    wait: settle,
    expect: () => const [
      SearchState(query: 'zzzz', status: RequestStatus.loading),
      SearchState(query: 'zzzz', status: RequestStatus.success, page: 1),
    ],
  );

  blocTest<SearchBloc, SearchState>(
    'emits failure (offline)',
    setUp: () => when(() => repository.search(any()))
        .thenThrow(const Failure(FailureCode.network)),
    build: build,
    act: (bloc) => bloc.add(const SearchQueryChanged('dune')),
    wait: settle,
    expect: () => const [
      SearchState(query: 'dune', status: RequestStatus.loading),
      SearchState(
        query: 'dune',
        status: RequestStatus.failure,
        failure: Failure(FailureCode.network),
      ),
    ],
  );

  blocTest<SearchBloc, SearchState>(
    'clearing the query returns to the initial state without a request',
    build: build,
    seed: () => SearchState(
      query: 'dune',
      status: RequestStatus.success,
      books: [dune],
      page: 1,
    ),
    act: (bloc) => bloc.add(const SearchQueryChanged('   ')),
    wait: settle,
    expect: () => const [SearchState()],
    verify: (_) => verifyNever(() => repository.search(any())),
  );

  group('pagination', () {
    final seeded = SearchState(
      query: 'dune',
      status: RequestStatus.success,
      books: [dune],
      page: 1,
      hasMore: true,
    );

    blocTest<SearchBloc, SearchState>(
      'appends the next page, skipping duplicates',
      setUp: () => when(() => repository.search('dune', page: 2)).thenAnswer(
        (_) async =>
            BookSearchPage(books: [dune, emma], page: 2, hasMore: false),
      ),
      build: build,
      seed: () => seeded,
      act: (bloc) => bloc.add(const SearchNextPageRequested()),
      expect: () => [
        seeded.copyWith(isLoadingMore: true),
        seeded.copyWith(books: [dune, emma], page: 2, hasMore: false),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'reports loadMoreFailure and keeps existing results',
      setUp: () => when(() => repository.search('dune', page: 2))
          .thenThrow(const Failure(FailureCode.timeout)),
      build: build,
      seed: () => seeded,
      act: (bloc) => bloc.add(const SearchNextPageRequested()),
      expect: () => [
        seeded.copyWith(isLoadingMore: true),
        seeded.copyWith(
          loadMoreFailure: () => const Failure(FailureCode.timeout),
        ),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'does nothing when there are no more pages',
      build: build,
      seed: () => seeded.copyWith(hasMore: false),
      act: (bloc) => bloc.add(const SearchNextPageRequested()),
      expect: () => const <SearchState>[],
      verify: (_) =>
          verifyNever(() => repository.search(any(), page: any(named: 'page'))),
    );
  });
}
