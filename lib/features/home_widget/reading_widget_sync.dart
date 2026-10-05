import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../../core/utils/minutes_text.dart';
import '../../l10n/gen/app_localizations.dart';
import '../library/domain/entities/reading_status.dart';
import '../library/domain/entities/user_book.dart';
import '../library/domain/repositories/library_repository.dart';
import '../library/presentation/widgets/book_extras_ui.dart';
import '../profile/domain/repositories/profile_repository.dart';
import '../reminders/data/device_l10n.dart';
import '../stats/domain/entities/reading_log.dart';
import '../stats/domain/repositories/reading_log_repository.dart';
import 'library_widget_data.dart';
import 'stats_widget_data.dart';
import 'widget_dates.dart';

/// What the home screen widget shows, as saved for the native side.
@immutable
class ReadingWidgetData {
  const ReadingWidgetData({
    required this.bookId,
    required this.title,
    required this.author,
    required this.progress,
    required this.progressLabel,
    required this.left,
    required this.finishBy,
    required this.since,
    required this.lastReadDay,
    required this.streak,
    required this.streakToday,
    required this.streakAlive,
    required this.streakNone,
    required this.readingLabel,
    required this.noBookLabel,
  });

  /// Null when no book is being read.
  final String? bookId;
  final String? title;
  final String? author;

  /// 0..100, or -1 when the length is unknown.
  final int progress;
  final String progressLabel;

  /// Extra lines for the large widget, empty when unknown: what is left,
  /// when it will be finished at the recent pace, since when it is read.
  final String left;
  final String finishBy;
  final String since;

  /// yyyy-MM-dd of the last day with reading, or empty. The widget compares
  /// it with its own "today", so it stays right after midnight without the
  /// app running.
  final String lastReadDay;

  /// Days in a row up to [lastReadDay]; the widget shows it only while the
  /// streak is alive (last read today or yesterday).
  final int streak;

  /// The streak line for: read today, read yesterday (still alive), neither.
  final String streakToday;
  final String streakAlive;
  final String streakNone;

  final String readingLabel;
  final String noBookLabel;

  /// Days of reading the finish estimate is based on.
  static const paceDays = 14;

  /// Works out the widget from the library and the reading log.
  static ReadingWidgetData compute({
    required List<UserBook> books,
    required List<ReadingLog> logs,
    required AppLocalizations l10n,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final today = DateTime(clock.year, clock.month, clock.day);
    final active = {
      for (final log in logs)
        if (log.hasActivity)
          DateTime(log.loggedOn.year, log.loggedOn.month, log.loggedOn.day),
    };
    final last =
        active.isEmpty ? null : active.reduce((a, b) => a.isAfter(b) ? a : b);
    var streak = 0;
    var cursor = last;
    while (cursor != null && active.contains(cursor)) {
      streak++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }

    // The book read most recently, if still in progress; else any.
    final reading = [
      for (final b in books)
        if (b.status == ReadingStatus.reading) b,
    ];
    final latestId = (logs.toList()
          ..sort((a, b) => b.loggedOn.compareTo(a.loggedOn)))
        .firstOrNull
        ?.userBookId;
    final book = reading.where((b) => b.id == latestId).firstOrNull ??
        reading.firstOrNull;
    final progress = book?.progress;

    return ReadingWidgetData(
      bookId: book?.id,
      title: book?.book.title,
      author: book?.book.authors.firstOrNull,
      progress: progress == null ? -1 : (progress * 100).round(),
      progressLabel: book?.progressLabel(l10n) ?? '',
      left: book == null ? '' : _left(book, l10n),
      finishBy: book == null ? '' : _finishBy(book, logs, today, l10n),
      since: book?.startedAt == null
          ? ''
          : l10n.widgetReadingSince(
              WidgetDates.short(book!.startedAt!, l10n.localeName),
            ),
      lastReadDay: last == null ? '' : WidgetDates.day(last),
      streak: streak,
      streakToday: '${l10n.widgetStreak(streak)} · ${l10n.widgetReadToday}',
      streakAlive: l10n.widgetStreak(streak),
      streakNone: l10n.widgetStreak(0),
      readingLabel: l10n.statusReading,
      noBookLabel: l10n.widgetNoBook,
    );
  }

  static int? _remaining(UserBook book) {
    final total = book.progressTotal;
    if (total == null) return null;
    final left = total - book.currentPage;
    return left > 0 ? left : null;
  }

  /// "160 pagine rimaste", or the time left of an audiobook.
  static String _left(UserBook book, AppLocalizations l10n) {
    final left = _remaining(book);
    if (left == null) return '';
    return book.isAudio
        ? l10n.widgetTimeLeft(MinutesText.format(l10n, left))
        : l10n.widgetPagesLeft(left);
  }

  /// The day the book will be finished at the pace of the last [paceDays]
  /// days, or empty without recent sessions.
  static String _finishBy(
    UserBook book,
    List<ReadingLog> logs,
    DateTime today,
    AppLocalizations l10n,
  ) {
    final left = _remaining(book);
    if (left == null) return '';
    final from = DateTime(today.year, today.month, today.day - paceDays + 1);
    var done = 0;
    for (final log in logs) {
      if (log.userBookId != book.id || log.loggedOn.isBefore(from)) continue;
      done += book.isAudio ? log.minutes ?? 0 : log.pages;
    }
    if (done <= 0) return '';
    final days = (left * paceDays / done).ceil();
    if (days > 366) return '';
    final finish = DateTime(today.year, today.month, today.day + days);
    return l10n.widgetFinishBy(WidgetDates.short(finish, l10n.localeName));
  }

  Map<String, Object> toMap() => {
        'has_book': title != null,
        'book_id': bookId ?? '',
        'title': title ?? '',
        'author': author ?? '',
        'progress': progress,
        'progress_label': progressLabel,
        'info_left': left,
        'info_finish': finishBy,
        'info_since': since,
        'last_read_day': lastReadDay,
        'streak_count': streak,
        'streak_today': streakToday,
        'streak_alive': streakAlive,
        'streak_none': streakNone,
        'label_reading': readingLabel,
        'label_no_book': noBookLabel,
      };
}

/// Keeps the home screen widgets (reading, library, statistics) in step with
/// the library, the reading log and the yearly goal (Android; see
/// ios/ReadingWidget for iOS).
class ReadingWidgetSync {
  ReadingWidgetSync(
    this._library,
    this._logs,
    this._profiles, {
    Locale Function()? locale,
    Future<void> Function(Map<String, Object> data)? publish,
  })  : _locale = locale ?? (() => PlatformDispatcher.instance.locale),
        _publish = publish ?? _publishToWidget;

  final LibraryRepository _library;
  final ReadingLogRepository _logs;
  final ProfileRepository _profiles;
  final Locale Function() _locale;
  final Future<void> Function(Map<String, Object> data) _publish;
  final _subscriptions = <StreamSubscription<Object?>>[];
  List<ReadingLog> _recentLogs = const [];
  int? _goal;
  bool _signedIn = false;

  /// Android provider class and iOS widget kind of each widget.
  static const widgets = {
    'ReadingWidgetProvider': 'ReadingWidget',
    'LibraryWidgetProvider': 'LibraryWidget',
    'StatsWidgetProvider': 'StatsWidget',
  };

  /// Shared with the iOS widget extension (see ios/ReadingWidget/README.md).
  /// Until the App Group exists the data just stays inside the app.
  static const iOSAppGroup = 'group.com.marcomanzalini.bookshelf';

  /// Enough history for any streak worth showing, and for this month.
  static const _historyDays = 60;

  void start() {
    if (_subscriptions.isNotEmpty) return;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      _safely(() async {
        await HomeWidget.setAppGroupId(iOSAppGroup);
      });
    }
    _subscriptions
      ..add(_library.books.listen((_) => _render()))
      ..add(_logs.changes.listen((_) => refresh()));
  }

  /// Reloads the reading log (for the streak) and the goal, and redraws.
  Future<void> refresh() async {
    _signedIn = true;
    final now = DateTime.now();
    await Future.wait([
      _safely(() async {
        _recentLogs = await _logs.all(
          since: DateTime(now.year, now.month, now.day - _historyDays),
        );
      }),
      _safely(() async {
        _goal = (await _profiles.getProfile()).readingGoal;
      }),
    ]);
    // Offline, the last known history and goal stay.
    await _render();
  }

  Future<void> _render() async {
    if (!_signedIn) return;
    await _safely(
      () => _publish(_compute(_library.cachedBooks, _recentLogs, _goal)),
    );
  }

  Map<String, Object> _compute(
    List<UserBook> books,
    List<ReadingLog> logs,
    int? goal,
  ) {
    final l10n = deviceL10n(_locale());
    return {
      ...ReadingWidgetData.compute(books: books, logs: logs, l10n: l10n)
          .toMap(),
      ...LibraryWidgetData.compute(books: books, l10n: l10n).toMap(),
      ...StatsWidgetData.compute(
        books: books,
        logs: logs,
        goal: goal,
        l10n: l10n,
      ).toMap(),
    };
  }

  /// On logout: empty widgets, not the previous account's books.
  Future<void> clear() async {
    _signedIn = false;
    _recentLogs = const [];
    _goal = null;
    await _safely(() => _publish(_compute(const [], const [], null)));
  }

  static Future<void> _safely(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      // No widget support on this platform, or no widget placed.
      debugPrint('Home widget not updated: $e');
    }
  }

  static Future<void> _publishToWidget(Map<String, Object> data) async {
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }
    for (final entry in data.entries) {
      await HomeWidget.saveWidgetData<Object>(entry.key, entry.value);
    }
    final now = DateTime.now();
    for (final widget in widgets.entries) {
      await _safely(() async {
        await HomeWidget.updateWidget(
          androidName: widget.key,
          iOSName: widget.value,
        );
        if (defaultTargetPlatform == TargetPlatform.android) {
          // Redraw just after each of the next midnights, so "read today"
          // turns into "read yesterday" without the app running.
          await HomeWidget.scheduleWidgetUpdates(
            [
              for (var d = 1; d <= 7; d++)
                DateTime(now.year, now.month, now.day + d, 0, 1),
            ],
            androidName: widget.key,
          );
        }
      });
    }
  }

  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
  }
}
