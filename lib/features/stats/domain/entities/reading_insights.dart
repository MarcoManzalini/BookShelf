import 'package:equatable/equatable.dart';

import '../../../library/domain/entities/reading_status.dart';
import '../../../library/domain/entities/user_book.dart';
import 'reading_log.dart';

/// Everything the statistics page shows, derived from the library and the
/// reading log. Pure: the same inputs always give the same numbers.
class ReadingInsights extends Equatable {
  const ReadingInsights({
    required this.booksReadTotal,
    required this.pagesReadTotal,
    required this.booksReadThisYear,
    required this.goal,
    required this.booksPerMonth,
    required this.pagesLast14Days,
    required this.streakDays,
    required this.avgPagesPerDay,
    required this.totalMinutes,
    required this.avgRating,
    required this.topSubjects,
  });

  factory ReadingInsights.compute({
    required List<UserBook> books,
    required List<ReadingLog> logs,
    int? goal,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final today = DateTime(clock.year, clock.month, clock.day);

    var booksRead = 0;
    var pagesRead = 0;
    var thisYear = 0;
    final perMonth = List.filled(12, 0);
    final ratings = <int>[];
    for (final b in books) {
      final rating = b.rating;
      if (rating != null) ratings.add(rating);
      if (b.status != ReadingStatus.read) continue;
      booksRead++;
      pagesRead += b.pageCount ?? 0;
      final finished = b.finishedAt;
      if (finished != null && finished.year == today.year) {
        thisYear++;
        perMonth[finished.month - 1]++;
      }
    }

    final pagesByDay = <DateTime, int>{};
    final activeDays = <DateTime>{};
    var minutes = 0;
    for (final log in logs) {
      final day = DateTime(
        log.loggedOn.year,
        log.loggedOn.month,
        log.loggedOn.day,
      );
      pagesByDay[day] = (pagesByDay[day] ?? 0) + log.pages;
      minutes += log.minutes ?? 0;
      if (log.hasActivity) activeDays.add(day);
    }

    DateTime daysAgo(int n) => DateTime(today.year, today.month, today.day - n);

    // The streak is still alive if the reader has not read *yet* today.
    var cursor = activeDays.contains(today) ? today : daysAgo(1);
    var streak = 0;
    while (activeDays.contains(cursor)) {
      streak++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }

    var last30 = 0;
    for (var i = 0; i < 30; i++) {
      last30 += pagesByDay[daysAgo(i)] ?? 0;
    }

    final subjectCounts = <String, int>{};
    final spelling = <String, String>{};
    for (final b in books) {
      for (final subject in b.book.subjects) {
        final key = subject.toLowerCase();
        final name = spelling.putIfAbsent(key, () => subject);
        subjectCounts[name] = (subjectCounts[name] ?? 0) + 1;
      }
    }
    final top = subjectCounts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });

    return ReadingInsights(
      booksReadTotal: booksRead,
      pagesReadTotal: pagesRead,
      booksReadThisYear: thisYear,
      goal: goal,
      booksPerMonth: perMonth,
      pagesLast14Days: [
        for (var i = 13; i >= 0; i--) pagesByDay[daysAgo(i)] ?? 0,
      ],
      streakDays: streak,
      avgPagesPerDay: (last30 / 30).round(),
      totalMinutes: minutes,
      avgRating: ratings.isEmpty
          ? null
          : ratings.reduce((a, b) => a + b) / ratings.length,
      topSubjects: [
        for (final e in top.take(5)) MapEntry(e.key, e.value),
      ],
    );
  }

  final int booksReadTotal;
  final int pagesReadTotal;
  final int booksReadThisYear;

  /// Books-per-year target, or null when the reader has not set one.
  final int? goal;

  /// Books finished in each month of the current year (Jan = index 0).
  final List<int> booksPerMonth;

  /// Pages logged per day, oldest first, ending today.
  final List<int> pagesLast14Days;
  final int streakDays;
  final int avgPagesPerDay;
  final int totalMinutes;
  final double? avgRating;
  final List<MapEntry<String, int>> topSubjects;

  /// 0..1 progress towards the goal, or null without one.
  double? get goalProgress {
    final target = goal;
    if (target == null || target <= 0) return null;
    return (booksReadThisYear / target).clamp(0.0, 1.0);
  }

  @override
  List<Object?> get props => [
        booksReadTotal,
        pagesReadTotal,
        booksReadThisYear,
        goal,
        booksPerMonth,
        pagesLast14Days,
        streakDays,
        avgPagesPerDay,
        totalMinutes,
        avgRating,
        topSubjects,
      ];
}
