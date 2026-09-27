import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/request_status.dart';
import '../../../library/domain/repositories/library_repository.dart';
import '../../../stats/domain/repositories/reading_log_repository.dart';
import '../../domain/reading_recap.dart';

class RecapState extends Equatable {
  const RecapState({
    this.status = RequestStatus.initial,
    this.recap,
    this.failure,
  });

  final RequestStatus status;
  final ReadingRecap? recap;
  final Failure? failure;

  @override
  List<Object?> get props => [status, recap, failure];
}

/// Loads the reading log of one period and works out its recap.
class RecapCubit extends Cubit<RecapState> {
  RecapCubit(this._logs, this._library, this.period)
      : super(const RecapState());

  final ReadingLogRepository _logs;
  final LibraryRepository _library;
  final RecapPeriod period;

  Future<void> load() async {
    emit(const RecapState(status: RequestStatus.loading));
    try {
      final logs = await _logs.all(since: period.start);
      emit(
        RecapState(
          status: RequestStatus.success,
          recap: ReadingRecap.compute(
            period: period,
            books: _library.cachedBooks,
            logs: logs,
          ),
        ),
      );
    } on Failure catch (failure) {
      emit(RecapState(status: RequestStatus.failure, failure: failure));
    }
  }
}
