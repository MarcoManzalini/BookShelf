import '../entities/reading_log.dart';

abstract interface class ReadingLogRepository {
  /// Records a session. Throws [Failure] on error.
  Future<ReadingLog> add({
    required String userBookId,
    required int pages,
    int? minutes,
    int? endPage,
    DateTime? on,
  });

  /// Sessions of one book, newest first.
  Future<List<ReadingLog>> forBook(String userBookId);

  /// Every session since [since] (all time when null), newest first.
  Future<List<ReadingLog>> all({DateTime? since});
}
