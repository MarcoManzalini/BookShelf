import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../../l10n/gen/app_localizations.dart';
import '../library/domain/entities/reading_status.dart';
import '../library/domain/entities/user_book.dart';
import '../library/domain/repositories/library_repository.dart';
import '../library/presentation/widgets/book_extras_ui.dart';
import '../reminders/data/device_l10n.dart';
import '../stats/domain/entities/reading_log.dart';
import '../stats/domain/repositories/reading_log_repository.dart';

/// What the home screen widget shows, as saved for the native side.
@immutable
class ReadingWidgetData {
  const ReadingWidgetData({
    required this.title,
    required this.author,
    required this.progress,
    required this.progressLabel,
    required this.lastReadDay,
    required this.streakToday,
    required this.streakAlive,
    required this.streakNone,
    required this.readingLabel,
    required this.noBookLabel,
  });

  /// Null when no book is being read.
  final String? title;
  final String? author;

  /// 0..100, or -1 when the length is unknown.
  final int progress;
  final String progressLabel;

  /// yyyy-MM-dd of the last day with reading, or empty. The widget compares
  /// it with its own "today", so it stays right after midnight without the
  /// app running.
  final String lastReadDay;

  /// The streak line for: read today, read yesterday (still alive), neither.
  final String streakToday;
  final String streakAlive;
  final String streakNone;

  final String readingLabel;
  final String noBookLabel;

  /// Works out the widget from the library and the reading log.
  static ReadingWidgetData compute({
    required List<UserBook> books,
    required List<ReadingLog> logs,
    required AppLocalizations l10n,
  }) {
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
      title: book?.book.title,
      author: book?.book.authors.firstOrNull,
      progress: progress == null ? -1 : (progress * 100).round(),
      progressLabel: book?.progressLabel(l10n) ?? '',
      lastReadDay: last == null ? '' : _day(last),
      streakToday: '${l10n.widgetStreak(streak)} · ${l10n.widgetReadToday}',
      streakAlive: l10n.widgetStreak(streak),
      streakNone: l10n.widgetStreak(0),
      readingLabel: l10n.statusReading,
      noBookLabel: l10n.widgetNoBook,
    );
  }

  static String _day(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Map<String, Object> toMap() => {
        'has_book': title != null,
        'title': title ?? '',
        'author': author ?? '',
        'progress': progress,
        'progress_label': progressLabel,
        'last_read_day': lastReadDay,
        'streak_today': streakToday,
        'streak_alive': streakAlive,
        'streak_none': streakNone,
        'label_reading': readingLabel,
        'label_no_book': noBookLabel,
      };
}

/// Keeps the home screen widget in step with the library and the reading
/// log (Android; see ios/ReadingWidget for iOS).
class ReadingWidgetSync {
  ReadingWidgetSync(
    this._library,
    this._logs, {
    Locale Function()? locale,
    Future<void> Function(Map<String, Object> data)? publish,
  })  : _locale = locale ?? (() => PlatformDispatcher.instance.locale),
        _publish = publish ?? _publishToWidget;

  final LibraryRepository _library;
  final ReadingLogRepository _logs;
  final Locale Function() _locale;
  final Future<void> Function(Map<String, Object> data) _publish;
  final _subscriptions = <StreamSubscription<Object?>>[];
  List<ReadingLog> _recentLogs = const [];
  bool _signedIn = false;

  static const androidProvider = 'ReadingWidgetProvider';
  static const iOSWidget = 'ReadingWidget';

  /// Shared with the iOS widget extension (see ios/ReadingWidget/README.md).
  /// Until the App Group exists the data just stays inside the app.
  static const iOSAppGroup = 'group.com.marcomanzalini.bookshelf';

  /// Enough history for any streak worth showing.
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

  /// Reloads the reading log (for the streak) and redraws.
  Future<void> refresh() async {
    _signedIn = true;
    try {
      final now = DateTime.now();
      _recentLogs = await _logs.all(
        since: DateTime(now.year, now.month, now.day - _historyDays),
      );
    } catch (_) {
      // Offline: keep the last known history.
    }
    await _render();
  }

  Future<void> _render() async {
    if (!_signedIn) return;
    final data = ReadingWidgetData.compute(
      books: _library.cachedBooks,
      logs: _recentLogs,
      l10n: deviceL10n(_locale()),
    );
    await _safely(() => _publish(data.toMap()));
  }

  /// On logout: an empty widget, not the previous account's book.
  Future<void> clear() async {
    _signedIn = false;
    _recentLogs = const [];
    final l10n = deviceL10n(_locale());
    await _safely(
      () => _publish(
        ReadingWidgetData.compute(books: const [], logs: const [], l10n: l10n)
            .toMap(),
      ),
    );
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
    await HomeWidget.updateWidget(
      androidName: androidProvider,
      iOSName: iOSWidget,
    );
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Redraw just after each of the next midnights, so "read today" turns
      // into "read yesterday" without the app running.
      final now = DateTime.now();
      await HomeWidget.scheduleWidgetUpdates(
        [
          for (var d = 1; d <= 7; d++)
            DateTime(now.year, now.month, now.day + d, 0, 1),
        ],
        androidName: androidProvider,
      );
    }
  }

  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
  }
}
