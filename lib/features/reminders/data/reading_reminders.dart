import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../library/domain/entities/reading_status.dart';
import '../../library/domain/repositories/library_repository.dart';
import '../../stats/domain/repositories/reading_log_repository.dart';
import '../domain/reminder_plan.dart';
import 'device_l10n.dart';
import 'reminder_scheduler.dart';

/// The daily reading reminder: a setting kept on this device, and the
/// notifications it schedules.
class ReadingReminders extends ChangeNotifier {
  ReadingReminders(
    this._prefs,
    this._logs,
    this._library,
    this._scheduler, {
    DateTime Function()? now,
    Locale Function()? locale,
  })  : _now = now ?? DateTime.now,
        _locale = locale ?? (() => PlatformDispatcher.instance.locale) {
    _logsChanged = _logs.changes.listen((_) => refresh());
  }

  final SharedPreferences _prefs;
  final ReadingLogRepository _logs;
  final LibraryRepository _library;
  final ReminderScheduler _scheduler;
  final DateTime Function() _now;
  final Locale Function() _locale;
  late final StreamSubscription<void> _logsChanged;

  static const _enabledKey = 'reminder_enabled';
  static const _timeKey = 'reminder_minutes';

  /// First notification id; the plan uses [ReminderPlan.days] from here.
  static const _firstId = 7100;

  /// 21:00: after dinner, a common time to read.
  static const defaultMinutes = 21 * 60;

  /// Enough history for any streak worth mentioning.
  static const _historyDays = 60;

  bool get enabled => _prefs.getBool(_enabledKey) ?? false;

  /// Minutes after midnight.
  int get minutes => _prefs.getInt(_timeKey) ?? defaultMinutes;

  /// Turns reminders on at [minutes] after midnight. False when the system
  /// refused permission to notify.
  Future<bool> enable({int? minutes}) async {
    if (!await _scheduler.requestPermission()) return false;
    if (minutes != null) await _prefs.setInt(_timeKey, minutes);
    await _prefs.setBool(_enabledKey, true);
    notifyListeners();
    await refresh();
    return true;
  }

  Future<void> disable() async {
    await _prefs.setBool(_enabledKey, false);
    notifyListeners();
    await _cancelAll();
  }

  Future<void> setTime(int minutes) async {
    await _prefs.setInt(_timeKey, minutes);
    notifyListeners();
    await refresh();
  }

  /// Rebuilds the scheduled notifications from the latest reading history.
  /// Keeps the current ones when the history cannot be loaded (offline).
  Future<void> refresh() async {
    if (!enabled) return;
    final List<DateTime> activeDays;
    String? latestBookId;
    try {
      final today = _now();
      final logs = await _logs.all(
        since: DateTime(today.year, today.month, today.day - _historyDays),
      );
      activeDays = [
        for (final log in logs)
          if (log.hasActivity) log.loggedOn,
      ];
      latestBookId = logs.firstOrNull?.userBookId;
    } catch (_) {
      return;
    }
    // Re-check: the reader may have turned reminders off meanwhile.
    if (!enabled) return;

    final slots = ReminderPlan.compute(
      now: _now(),
      hour: minutes ~/ 60,
      minute: minutes % 60,
      activeDays: activeDays,
      bookTitle: _bookInProgress(latestBookId),
    );
    final l10n = deviceL10n(_locale());
    try {
      await _cancelAll();
      for (var i = 0; i < slots.length; i++) {
        final slot = slots[i];
        final (title, body) = switch (slot.message) {
          StreakReminder(:final days) => (
              l10n.reminderStreakTitle,
              l10n.reminderStreakBody(days),
            ),
          NudgeReminder(:final bookTitle?) => (
              l10n.reminderNudgeTitle,
              l10n.reminderNudgeBook(bookTitle),
            ),
          NudgeReminder() => (l10n.reminderNudgeTitle, l10n.reminderNudgeBody),
        };
        await _scheduler.schedule(
          id: _firstId + i,
          at: slot.at,
          title: title,
          body: body,
          channelName: l10n.reminderChannel,
        );
      }
    } catch (e) {
      // Scheduling is best effort: the app works the same without it.
      debugPrint('Reading reminders not scheduled: $e');
    }
  }

  /// Removes this account's reminders (on logout) but keeps the setting for
  /// the next sign-in on this device.
  Future<void> clear() async {
    try {
      await _cancelAll();
    } catch (_) {
      // Nothing scheduled, or notifications unavailable.
    }
  }

  /// The book last read if it is still in progress, else any book being
  /// read.
  String? _bookInProgress(String? latestBookId) {
    final reading = _library.cachedBooks
        .where((b) => b.status == ReadingStatus.reading)
        .toList();
    final latest = reading.where((b) => b.id == latestBookId).firstOrNull;
    return (latest ?? reading.firstOrNull)?.book.title;
  }

  Future<void> _cancelAll() async {
    for (var i = 0; i < ReminderPlan.days; i++) {
      await _scheduler.cancel(_firstId + i);
    }
  }

  @override
  void dispose() {
    _logsChanged.cancel();
    super.dispose();
  }
}
