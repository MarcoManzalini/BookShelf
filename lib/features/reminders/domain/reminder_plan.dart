import 'package:equatable/equatable.dart';

/// What a reminder says: that a streak is at stake, or a plain nudge.
sealed class ReminderMessage extends Equatable {
  const ReminderMessage();
}

/// The reader has read [days] days in a row and has not read yet on the day
/// of the reminder.
final class StreakReminder extends ReminderMessage {
  const StreakReminder(this.days);

  final int days;

  @override
  List<Object?> get props => [days];
}

/// An invitation to read, naming the book in progress when there is one.
final class NudgeReminder extends ReminderMessage {
  const NudgeReminder([this.bookTitle]);

  final String? bookTitle;

  @override
  List<Object?> get props => [bookTitle];
}

class ReminderSlot extends Equatable {
  const ReminderSlot(this.at, this.message);

  final DateTime at;
  final ReminderMessage message;

  @override
  List<Object?> get props => [at, message];
}

/// The daily reminders for the coming days, worked out from the reading
/// history. Each one is a separate one-shot notification, so the text can
/// depend on the streak; the plan is rebuilt whenever the app opens or a
/// session is logged.
abstract final class ReminderPlan {
  /// How many days ahead are scheduled: enough that a reader who does not
  /// open the app for a few days still gets reminded.
  static const days = 7;

  static List<ReminderSlot> compute({
    required DateTime now,
    required int hour,
    required int minute,
    required Iterable<DateTime> activeDays,
    String? bookTitle,
  }) {
    final active = {
      for (final d in activeDays) DateTime(d.year, d.month, d.day),
    };
    final today = DateTime(now.year, now.month, now.day);
    final readToday = active.contains(today);

    // Days in a row up to today, or up to yesterday while today is still
    // open.
    var streak = 0;
    var cursor = readToday ? today : DateTime(now.year, now.month, now.day - 1);
    while (active.contains(cursor)) {
      streak++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }

    final slots = <ReminderSlot>[];
    for (var d = 0; d < days; d++) {
      // Nothing to remind about on a day the reader already read.
      if (d == 0 && readToday) continue;
      final at = DateTime(now.year, now.month, now.day + d, hour, minute);
      if (!at.isAfter(now)) continue;
      // The streak survives only until the first reminder: today's if the
      // reader has not read yet, tomorrow's if they already did.
      final atStake = streak > 0 && (d == 0 || (d == 1 && readToday));
      slots.add(
        ReminderSlot(
          at,
          atStake ? StreakReminder(streak) : NudgeReminder(bookTitle),
        ),
      );
    }
    return slots;
  }
}
