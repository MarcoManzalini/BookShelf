import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/request_status.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../domain/entities/reading_log.dart';
import '../../domain/repositories/reading_log_repository.dart';

class StatsState extends Equatable {
  const StatsState({
    this.status = RequestStatus.initial,
    this.logs = const [],
    this.goal,
    this.failure,
    this.goalFailure,
  });

  final RequestStatus status;
  final List<ReadingLog> logs;
  final int? goal;
  final Failure? failure;

  /// The last attempt to save the goal failed (drives a snackbar).
  final Failure? goalFailure;

  StatsState copyWith({
    RequestStatus? status,
    List<ReadingLog>? logs,
    int? Function()? goal,
    Failure? Function()? failure,
    Failure? Function()? goalFailure,
  }) =>
      StatsState(
        status: status ?? this.status,
        logs: logs ?? this.logs,
        goal: goal != null ? goal() : this.goal,
        failure: failure != null ? failure() : this.failure,
        goalFailure: goalFailure != null ? goalFailure() : this.goalFailure,
      );

  @override
  List<Object?> get props => [status, logs, goal, failure, goalFailure];
}

/// Loads what the statistics need beyond the library itself: the reading log
/// and the yearly goal.
class StatsCubit extends Cubit<StatsState> {
  StatsCubit(this._logs, this._profiles, {DateTime Function()? now})
      : _now = now ?? DateTime.now,
        super(const StatsState());

  final ReadingLogRepository _logs;
  final ProfileRepository _profiles;
  final DateTime Function() _now;

  /// Enough history for a year's charts and long streaks.
  static const historyDays = 400;

  Future<void> load() async {
    emit(state.copyWith(status: RequestStatus.loading, failure: () => null));
    final today = _now();
    final since = DateTime(today.year, today.month, today.day - historyDays);
    try {
      final results = await Future.wait([
        _logs.all(since: since),
        _profiles.getProfile(),
      ]);
      emit(
        state.copyWith(
          status: RequestStatus.success,
          logs: results[0] as List<ReadingLog>,
          goal: () => (results[1] as Profile).readingGoal,
        ),
      );
    } on Failure catch (failure) {
      emit(
        state.copyWith(status: RequestStatus.failure, failure: () => failure),
      );
    }
  }

  /// [goal] null removes the target.
  Future<void> setGoal(int? goal) async {
    final previous = state.goal;
    emit(state.copyWith(goal: () => goal, goalFailure: () => null));
    try {
      final profile = await _profiles.updateReadingGoal(goal);
      emit(state.copyWith(goal: () => profile.readingGoal));
    } on Failure catch (failure) {
      emit(state.copyWith(goal: () => previous, goalFailure: () => failure));
    }
  }
}
