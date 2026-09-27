import 'package:equatable/equatable.dart';

import '../../../library/domain/entities/user_book.dart';
import 'reading_log.dart';

/// Everything the "books per month" chart shows once a specific bar is
/// tapped: the exact books finished and reading activity for that month.
class MonthDetail extends Equatable {
  const MonthDetail({
    required this.month,
    required this.booksFinished,
    required this.pagesRead,
    required this.minutesRead,
    required this.activeDays,
    required this.sessionsCount,
  });

  /// First day of the month this detail covers.
  final DateTime month;

  /// Books with a read finished within [month] (a re-read counts too),
  /// newest first.
  final List<UserBook> booksFinished;

  /// Sum of [ReadingLog.pages] logged within [month].
  final int pagesRead;

  /// Sum of [ReadingLog.minutes] logged within [month].
  final int minutesRead;

  /// Distinct calendar days in [month] with at least one active session.
  final int activeDays;

  /// Number of logged sessions with activity in [month].
  final int sessionsCount;

  static MonthDetail compute({
    required List<UserBook> books,
    required List<ReadingLog> logs,
    required int year,
    required int month,
  }) {
    // Latest finish within the month for each book, if any.
    final finishedOn = <UserBook, DateTime>{};
    for (final book in books) {
      for (final read in book.completedReads) {
        final day = read.finishedAt;
        if (day == null || day.year != year || day.month != month) continue;
        final seen = finishedOn[book];
        if (seen == null || day.isAfter(seen)) finishedOn[book] = day;
      }
    }
    final finished = finishedOn.keys.toList()
      ..sort((a, b) => finishedOn[b]!.compareTo(finishedOn[a]!));

    var pages = 0;
    var minutes = 0;
    var sessions = 0;
    final activeDays = <int>{};
    for (final log in logs) {
      if (log.loggedOn.year != year || log.loggedOn.month != month) continue;
      pages += log.pages;
      minutes += log.minutes ?? 0;
      if (log.hasActivity) {
        sessions++;
        activeDays.add(log.loggedOn.day);
      }
    }

    return MonthDetail(
      month: DateTime(year, month),
      booksFinished: finished,
      pagesRead: pages,
      minutesRead: minutes,
      activeDays: activeDays.length,
      sessionsCount: sessions,
    );
  }

  @override
  List<Object?> get props => [
        month,
        booksFinished,
        pagesRead,
        minutesRead,
        activeDays,
        sessionsCount,
      ];
}
