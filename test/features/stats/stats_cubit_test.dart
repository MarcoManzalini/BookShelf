import 'package:bloc_test/bloc_test.dart';
import 'package:bookshelf/core/errors/failure.dart';
import 'package:bookshelf/core/utils/request_status.dart';
import 'package:bookshelf/features/profile/domain/entities/profile.dart';
import 'package:bookshelf/features/profile/domain/repositories/profile_repository.dart';
import 'package:bookshelf/features/stats/domain/entities/reading_log.dart';
import 'package:bookshelf/features/stats/presentation/cubit/stats_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockReadingLogRepository logs;
  late MockProfileRepository profiles;

  final today = DateTime(2026, 9, 20);
  final log = ReadingLog(
    id: 'l1',
    userBookId: 'ub-1',
    loggedOn: today,
    pages: 12,
  );
  const profile = Profile(id: 'u1', readingGoal: 12);

  setUpAll(() => registerFallbackValue(DateTime(2000)));

  setUp(() {
    logs = MockReadingLogRepository();
    profiles = MockProfileRepository();
  });

  StatsCubit build() => StatsCubit(logs, profiles, now: () => today);

  blocTest<StatsCubit, StatsState>(
    'loads the log and the goal',
    setUp: () {
      when(() => logs.all(since: any(named: 'since')))
          .thenAnswer((_) async => [log]);
      when(() => profiles.getProfile()).thenAnswer((_) async => profile);
    },
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      const StatsState(status: RequestStatus.loading),
      StatsState(status: RequestStatus.success, logs: [log], goal: 12),
    ],
    verify: (_) {
      final since = verify(() => logs.all(since: captureAny(named: 'since')))
          .captured
          .single as DateTime;
      expect(today.difference(since).inDays, StatsCubit.historyDays);
    },
  );

  blocTest<StatsCubit, StatsState>(
    'reports a load failure',
    setUp: () {
      when(() => logs.all(since: any(named: 'since')))
          .thenThrow(const Failure(FailureCode.network));
      when(() => profiles.getProfile()).thenAnswer((_) async => profile);
    },
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => const [
      StatsState(status: RequestStatus.loading),
      StatsState(
        status: RequestStatus.failure,
        failure: Failure(FailureCode.network),
      ),
    ],
  );

  blocTest<StatsCubit, StatsState>(
    'setting the goal shows it at once and keeps the saved value',
    setUp: () => when(() => profiles.updateReadingGoal(20)).thenAnswer(
      (_) async => const Profile(id: 'u1', readingGoal: 20),
    ),
    build: build,
    act: (cubit) => cubit.setGoal(20),
    expect: () => const [
      StatsState(goal: 20),
    ],
    verify: (cubit) => expect(cubit.state.goal, 20),
  );

  blocTest<StatsCubit, StatsState>(
    'a goal that cannot be saved is rolled back',
    setUp: () => when(() => profiles.updateReadingGoal(any()))
        .thenThrow(const Failure(FailureCode.network)),
    build: build,
    seed: () => const StatsState(status: RequestStatus.success, goal: 12),
    act: (cubit) => cubit.setGoal(30),
    verify: (cubit) {
      expect(cubit.state.goal, 12);
      expect(cubit.state.goalFailure, const Failure(FailureCode.network));
    },
  );

  blocTest<StatsCubit, StatsState>(
    'the goal can be removed',
    setUp: () => when(() => profiles.updateReadingGoal(null))
        .thenAnswer((_) async => const Profile(id: 'u1')),
    build: build,
    seed: () => const StatsState(status: RequestStatus.success, goal: 12),
    act: (cubit) => cubit.setGoal(null),
    verify: (cubit) => expect(cubit.state.goal, isNull),
  );
}
