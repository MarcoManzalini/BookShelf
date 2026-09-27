import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../library/domain/entities/book_loan.dart';
import '../../library/domain/entities/user_book.dart';
import '../../library/domain/repositories/library_repository.dart';
import 'device_l10n.dart';
import 'reminder_scheduler.dart';

/// A notification on the morning a loan is due: the reader's own books
/// coming back, or borrowed ones to return. Follows the library, so adding,
/// changing or closing a loan reschedules on its own.
class LoanReminders {
  LoanReminders(
    this._prefs,
    this._library,
    this._scheduler, {
    DateTime Function()? now,
    Locale Function()? locale,
  })  : _now = now ?? DateTime.now,
        _locale = locale ?? (() => PlatformDispatcher.instance.locale) {
    _subscription = _library.books.listen(update);
  }

  final SharedPreferences _prefs;
  final LibraryRepository _library;
  final ReminderScheduler _scheduler;
  final DateTime Function() _now;
  final Locale Function() _locale;
  late final StreamSubscription<List<UserBook>> _subscription;

  /// Ids 7200..7249: one per loan, well clear of the reading reminders.
  static const _firstId = 7200;
  static const maxLoans = 50;

  /// Morning of the due day.
  static const hour = 10;

  static const _askedKey = 'loan_permission_asked';

  /// What was last scheduled, to skip the work when the loans did not change.
  String? _scheduled;

  /// Due loans that still have a notification ahead, earliest first.
  @visibleForTesting
  static List<UserBook> upcoming(List<UserBook> books, DateTime now) {
    final due = [
      for (final b in books)
        if (b.loan?.due != null && _at(b.loan!.due!).isAfter(now)) b,
    ]..sort((a, b) => a.loan!.due!.compareTo(b.loan!.due!));
    return due.take(maxLoans).toList();
  }

  static DateTime _at(DateTime day) =>
      DateTime(day.year, day.month, day.day, hour);

  Future<void> _queue = Future.value();

  /// Library updates can arrive in bursts: they are handled one at a time,
  /// so cancelling and scheduling never interleave.
  Future<void> update(List<UserBook> books) =>
      _queue = _queue.then((_) => _update(books));

  Future<void> _update(List<UserBook> books) async {
    final loans = upcoming(books, _now());
    final signature = [
      for (final b in loans)
        '${b.id}|${b.loan!.kind.name}|${b.loan!.person}|${b.loan!.due}|'
            '${b.book.title}',
    ].join('\n');
    if (signature == _scheduled) return;
    try {
      if (loans.isNotEmpty && !await _mayNotify()) return;
      await _cancelAll();
      final l10n = deviceL10n(_locale());
      for (final (i, book) in loans.indexed) {
        final loan = book.loan!;
        final lent = loan.kind == LoanKind.lent;
        await _scheduler.schedule(
          id: _firstId + i,
          at: _at(loan.due!),
          title: lent ? l10n.loanNotifLentTitle : l10n.loanNotifBorrowedTitle,
          body: lent
              ? l10n.loanNotifLentBody(book.book.title, loan.person)
              : l10n.loanNotifBorrowedBody(book.book.title, loan.person),
          channelName: l10n.loanChannel,
        );
      }
      _scheduled = signature;
    } catch (e) {
      debugPrint('Loan reminders not scheduled: $e');
    }
  }

  /// Asks for permission the first time a due date is set, and never nags
  /// again: after a refusal the loans simply have no notification.
  Future<bool> _mayNotify() async {
    if (_prefs.getBool(_askedKey) ?? false) return true;
    await _prefs.setBool(_askedKey, true);
    return _scheduler.requestPermission();
  }

  /// On logout: the next account has its own loans.
  Future<void> clear() async {
    _scheduled = null;
    try {
      await _cancelAll();
    } catch (_) {
      // Notifications unavailable.
    }
  }

  Future<void> _cancelAll() async {
    for (var i = 0; i < maxLoans; i++) {
      await _scheduler.cancel(_firstId + i);
    }
  }

  void dispose() => _subscription.cancel();
}
