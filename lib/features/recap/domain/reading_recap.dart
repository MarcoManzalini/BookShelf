import 'package:equatable/equatable.dart';

import '../../library/domain/entities/book_format.dart';
import '../../library/domain/entities/book_vibe.dart';
import '../../library/domain/entities/user_book.dart';
import '../../stats/domain/entities/reading_log.dart';

/// The period a recap covers: a whole year or one month of it.
class RecapPeriod extends Equatable {
  const RecapPeriod.year(this.year) : month = null;

  const RecapPeriod.month(this.year, int this.month);

  final int year;

  /// 1..12, or null for the whole year.
  final int? month;

  bool get isYear => month == null;

  DateTime get start => DateTime(year, month ?? 1);

  /// First day after the period.
  DateTime get end => isYear ? DateTime(year + 1) : DateTime(year, month! + 1);

  bool contains(DateTime day) => !day.isBefore(start) && day.isBefore(end);

  @override
  List<Object?> get props => [year, month];
}

/// A finished read inside the period.
class RecapRead extends Equatable {
  const RecapRead(this.book, this.finishedAt, {this.startedAt});

  final UserBook book;
  final DateTime finishedAt;
  final DateTime? startedAt;

  /// Days from start to finish, counting both (a book read in one day: 1).
  int? get days {
    final start = startedAt;
    if (start == null || start.isAfter(finishedAt)) return null;
    return finishedAt.difference(start).inDays + 1;
  }

  @override
  List<Object?> get props => [book.id, finishedAt, startedAt];
}

/// Everything the "year (or month) in reading" story shows. Pure: derived
/// from the library and the reading log only.
class ReadingRecap extends Equatable {
  const ReadingRecap({
    required this.period,
    required this.finished,
    required this.pagesRead,
    required this.minutesRead,
    required this.activeDays,
    required this.longestStreak,
    this.bestDay,
    this.bestDayPages = 0,
    this.favoriteWeekday,
    this.topRated,
    this.longest,
    this.fastest,
    this.topSubject,
    this.topMood,
    this.formats = const {},
    this.rereads = 0,
    this.busiestMonth,
  });

  factory ReadingRecap.compute({
    required RecapPeriod period,
    required List<UserBook> books,
    required List<ReadingLog> logs,
  }) {
    // Finished reads in the period, latest first.
    final finished = <RecapRead>[];
    var rereads = 0;
    for (final book in books) {
      // Oldest first; undated reads (imported counts) are the oldest.
      final reads = [...book.completedReads]..sort((a, b) {
          final fa = a.finishedAt;
          final fb = b.finishedAt;
          if (fa == null) return fb == null ? 0 : -1;
          if (fb == null) return 1;
          return fa.compareTo(fb);
        });
      for (final (i, read) in reads.indexed) {
        final day = read.finishedAt;
        if (day == null || !period.contains(day)) continue;
        finished.add(RecapRead(book, day, startedAt: read.startedAt));
        // Any read but the first of a book is a re-read.
        if (i > 0) rereads++;
      }
    }
    finished.sort((a, b) => b.finishedAt.compareTo(a.finishedAt));

    // Reading activity from the log.
    final pagesByDay = <DateTime, int>{};
    final active = <DateTime>{};
    var pages = 0;
    var minutes = 0;
    for (final log in logs) {
      final day = DateTime(
        log.loggedOn.year,
        log.loggedOn.month,
        log.loggedOn.day,
      );
      if (!period.contains(day)) continue;
      pages += log.pages;
      minutes += log.minutes ?? 0;
      pagesByDay[day] = (pagesByDay[day] ?? 0) + log.pages;
      if (log.hasActivity) active.add(day);
    }
    // Without a log (books only marked as read), the pages of the books.
    if (pages == 0) {
      for (final read in finished) {
        if (!read.book.isAudio) pages += read.book.pageCount ?? 0;
      }
    }

    var longestStreak = 0;
    for (final day in active) {
      // Count only from the first day of each run.
      if (active.contains(DateTime(day.year, day.month, day.day - 1))) {
        continue;
      }
      var run = 0;
      var cursor = day;
      while (active.contains(cursor)) {
        run++;
        cursor = DateTime(cursor.year, cursor.month, cursor.day + 1);
      }
      if (run > longestStreak) longestStreak = run;
    }

    DateTime? bestDay;
    var bestPages = 0;
    final byWeekday = <int, int>{};
    for (final entry in pagesByDay.entries) {
      if (entry.value > bestPages) {
        bestPages = entry.value;
        bestDay = entry.key;
      }
    }
    for (final day in active) {
      byWeekday[day.weekday] = (byWeekday[day.weekday] ?? 0) + 1;
    }

    final rated = [
      for (final r in finished)
        if (r.book.rating != null) r,
    ]..sort((a, b) => b.book.rating!.compareTo(a.book.rating!));
    final paper = [
      for (final r in finished)
        if (!r.book.isAudio && r.book.pageCount != null) r,
    ]..sort((a, b) => b.book.pageCount!.compareTo(a.book.pageCount!));
    final timed = [
      for (final r in finished)
        if (r.days != null) r,
    ]..sort((a, b) => a.days!.compareTo(b.days!));

    final formats = <BookFormat, int>{};
    final subjects = <String, int>{};
    final spelling = <String, String>{};
    final moods = <BookMood, int>{};
    final perMonth = <int, int>{};
    for (final r in finished) {
      formats[r.book.format] = (formats[r.book.format] ?? 0) + 1;
      for (final subject in r.book.book.subjects) {
        final name = spelling.putIfAbsent(subject.toLowerCase(), () => subject);
        subjects[name] = (subjects[name] ?? 0) + 1;
      }
      for (final mood in r.book.moods) {
        moods[mood] = (moods[mood] ?? 0) + 1;
      }
      perMonth[r.finishedAt.month] = (perMonth[r.finishedAt.month] ?? 0) + 1;
    }

    return ReadingRecap(
      period: period,
      finished: finished,
      pagesRead: pages,
      minutesRead: minutes,
      activeDays: active.length,
      longestStreak: longestStreak,
      bestDay: bestDay,
      bestDayPages: bestPages,
      favoriteWeekday: _top(byWeekday),
      topRated: rated.firstOrNull,
      longest: paper.firstOrNull,
      fastest: timed.firstOrNull,
      topSubject: _top(subjects),
      topMood: _top(moods),
      formats: formats,
      rereads: rereads,
      busiestMonth: period.isYear ? _top(perMonth) : null,
    );
  }

  /// The key with the highest count; ties go to the first one seen.
  static K? _top<K>(Map<K, int> counts) {
    K? best;
    var max = 0;
    for (final entry in counts.entries) {
      if (entry.value > max) {
        max = entry.value;
        best = entry.key;
      }
    }
    return best;
  }

  final RecapPeriod period;

  /// Reads finished in the period, latest first (a book read twice appears
  /// twice).
  final List<RecapRead> finished;
  final int pagesRead;
  final int minutesRead;
  final int activeDays;
  final int longestStreak;

  /// The day with the most pages, and how many.
  final DateTime? bestDay;
  final int bestDayPages;

  /// [DateTime.weekday] the reader read on most often.
  final int? favoriteWeekday;
  final RecapRead? topRated;
  final RecapRead? longest;
  final RecapRead? fastest;
  final String? topSubject;
  final BookMood? topMood;
  final Map<BookFormat, int> formats;
  final int rereads;

  /// Month (1..12) with the most books finished, for a yearly recap.
  final int? busiestMonth;

  bool get isEmpty => finished.isEmpty && activeDays == 0;

  @override
  List<Object?> get props => [
        period,
        finished,
        pagesRead,
        minutesRead,
        activeDays,
        longestStreak,
        bestDay,
        bestDayPages,
        favoriteWeekday,
        topRated,
        longest,
        fastest,
        topSubject,
        topMood,
        formats,
        rereads,
        busiestMonth,
      ];
}
