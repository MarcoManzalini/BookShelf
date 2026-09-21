import 'package:bloc_test/bloc_test.dart';
import 'package:bookshelf/core/errors/failure.dart';
import 'package:bookshelf/core/utils/request_status.dart';
import 'package:bookshelf/features/search/domain/entities/explore_section.dart';
import 'package:bookshelf/features/search/presentation/bloc/explore_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';

void main() {
  late MockBookSearchRepository repository;

  final dune = buildBook(id: 'OL1W');
  final emma = buildBook(id: 'OL2W', title: 'Emma');

  setUpAll(() => registerFallbackValue(ExploreSection.popular));

  setUp(() => repository = MockBookSearchRepository());

  void stub(ExploreSection section, List<dynamic> books) => when(
        () => repository.getExploreSection(
          section,
          refresh: any(named: 'refresh'),
        ),
      ).thenAnswer((_) async => books.cast());

  ExploreBloc build() => ExploreBloc(repository);

  blocTest<ExploreBloc, ExploreState>(
    'loads every shelf and ends idle',
    setUp: () {
      stub(ExploreSection.bestSellers, [dune]);
      stub(ExploreSection.newArrivals, [emma]);
      stub(ExploreSection.popular, [dune, emma]);
    },
    build: build,
    act: (bloc) => bloc.add(const ExploreStarted()),
    verify: (bloc) {
      final state = bloc.state;
      expect(state.refreshing, isFalse);
      expect(state.of(ExploreSection.bestSellers).books, [dune]);
      expect(state.of(ExploreSection.newArrivals).books, [emma]);
      expect(state.of(ExploreSection.popular).books, [dune, emma]);
      for (final section in ExploreSection.values) {
        expect(state.of(section).status, RequestStatus.success);
      }
    },
  );

  blocTest<ExploreBloc, ExploreState>(
    'a failing shelf does not block the others',
    setUp: () {
      stub(ExploreSection.bestSellers, [dune]);
      when(
        () => repository.getExploreSection(
          ExploreSection.newArrivals,
          refresh: any(named: 'refresh'),
        ),
      ).thenThrow(const Failure(FailureCode.network));
      stub(ExploreSection.popular, [emma]);
    },
    build: build,
    act: (bloc) => bloc.add(const ExploreStarted()),
    verify: (bloc) {
      final state = bloc.state;
      expect(state.of(ExploreSection.bestSellers).books, [dune]);
      expect(
        state.of(ExploreSection.newArrivals).failure,
        const Failure(FailureCode.network),
      );
      expect(state.of(ExploreSection.popular).books, [emma]);
    },
  );

  blocTest<ExploreBloc, ExploreState>(
    'refresh bypasses the cache and keeps books shown when it fails',
    setUp: () {
      stub(ExploreSection.bestSellers, [dune]);
      stub(ExploreSection.newArrivals, [emma]);
      stub(ExploreSection.popular, [dune]);
    },
    build: build,
    act: (bloc) async {
      bloc.add(const ExploreStarted());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      when(
        () => repository.getExploreSection(
          any(),
          refresh: true,
        ),
      ).thenThrow(const Failure(FailureCode.timeout));
      bloc.add(const ExploreRefreshRequested());
    },
    wait: const Duration(milliseconds: 60),
    verify: (bloc) {
      verify(
        () => repository.getExploreSection(
          ExploreSection.bestSellers,
          refresh: true,
        ),
      ).called(1);
      final shelf = bloc.state.of(ExploreSection.bestSellers);
      expect(shelf.books, [dune]);
      expect(shelf.status, RequestStatus.success);
      expect(bloc.state.refreshing, isFalse);
    },
  );
}
