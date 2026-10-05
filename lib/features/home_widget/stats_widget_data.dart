import 'package:flutter/foundation.dart';

import '../../l10n/gen/app_localizations.dart';
import '../library/domain/entities/user_book.dart';
import '../stats/domain/entities/reading_insights.dart';
import '../stats/domain/entities/reading_log.dart';

/// What the statistics widget shows. The streak itself comes from the
/// reading widget's data (`streak_count`, `last_read_day`), shared by both.
@immutable
class StatsWidgetData {
  const StatsWidgetData({
    required this.booksThisYear,
    required this.goalProgress,
    required this.pagesThisMonth,
    required this.avgPagesPerDay,
    required this.labels,
  });

  final int booksThisYear;

  /// 0..100, or -1 without a goal.
  final int goalProgress;
  final int pagesThisMonth;
  final int avgPagesPerDay;
  final Map<String, String> labels;

  static StatsWidgetData compute({
    required List<UserBook> books,
    required List<ReadingLog> logs,
    required int? goal,
    required AppLocalizations l10n,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final insights = ReadingInsights.compute(
      books: books,
      logs: logs,
      goal: goal,
      now: today,
    );
    var month = 0;
    for (final log in logs) {
      if (log.loggedOn.year == today.year &&
          log.loggedOn.month == today.month) {
        month += log.pages;
      }
    }
    final progress = insights.goalProgress;
    final done = insights.booksReadThisYear;
    return StatsWidgetData(
      booksThisYear: done,
      goalProgress: progress == null ? -1 : (progress * 100).round(),
      pagesThisMonth: month,
      avgPagesPerDay: insights.avgPagesPerDay,
      labels: {
        'stat_label_year': l10n.widgetYear(today.year),
        'stat_label_books': l10n.widgetBooksRead(done),
        'stat_label_goal': goal == null || goal <= 0
            ? l10n.widgetNoGoal
            : l10n.widgetGoal(done, goal),
        'stat_label_streak': l10n.widgetDayStreak,
        'stat_label_month': l10n.widgetPagesMonth,
        'stat_label_avg': l10n.widgetPagesPerDay,
      },
    );
  }

  Map<String, Object> toMap() => {
        'stat_books_year': booksThisYear,
        'stat_goal_progress': goalProgress,
        'stat_pages_month': pagesThisMonth,
        'stat_avg_pages': avgPagesPerDay,
        ...labels,
      };
}
