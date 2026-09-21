import '../../../../core/errors/error_mapper.dart';
import '../../domain/entities/reading_log.dart';
import '../../domain/repositories/reading_log_repository.dart';
import '../datasources/reading_log_remote_data_source.dart';
import '../mappers/reading_log_mapper.dart';

class ReadingLogRepositoryImpl implements ReadingLogRepository {
  const ReadingLogRepositoryImpl(this._remote);

  final ReadingLogRemoteDataSource _remote;

  @override
  Future<ReadingLog> add({
    required String userBookId,
    required int pages,
    int? minutes,
    int? endPage,
    DateTime? on,
  }) {
    return _guard(
      () => _remote.insert(
        ReadingLogMapper.toInsertJson(
          userBookId: userBookId,
          pages: pages,
          minutes: minutes,
          endPage: endPage,
          on: on ?? DateTime.now(),
        ),
      ),
    );
  }

  @override
  Future<List<ReadingLog>> forBook(String userBookId) =>
      _guard(() => _remote.fetchForBook(userBookId));

  @override
  Future<List<ReadingLog>> all({DateTime? since}) =>
      _guard(() => _remote.fetchAll(since: since));

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      throw mapError(e);
    }
  }
}
