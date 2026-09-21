import 'package:equatable/equatable.dart';

/// One reading session: some pages (and possibly minutes) read on a day.
class ReadingLog extends Equatable {
  const ReadingLog({
    required this.id,
    required this.userBookId,
    required this.loggedOn,
    required this.pages,
    this.minutes,
    this.endPage,
  });

  final String id;
  final String userBookId;

  /// Calendar day of the session (time of day is dropped).
  final DateTime loggedOn;
  final int pages;
  final int? minutes;

  /// Page the reader had reached at the end of the session.
  final int? endPage;

  bool get hasActivity => pages > 0 || (minutes ?? 0) > 0;

  @override
  List<Object?> get props =>
      [id, userBookId, loggedOn, pages, minutes, endPage];
}
