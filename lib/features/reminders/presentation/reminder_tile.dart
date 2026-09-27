import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/utils/l10n_extension.dart';
import '../data/reading_reminders.dart';

/// Profile setting for the daily reading reminder: on/off and the time.
class ReminderTile extends StatefulWidget {
  const ReminderTile({super.key, this.reminders});

  /// Defaults to the app-wide instance.
  final ReadingReminders? reminders;

  @override
  State<ReminderTile> createState() => _ReminderTileState();
}

class _ReminderTileState extends State<ReminderTile> {
  late final ReadingReminders _reminders =
      widget.reminders ?? getIt<ReadingReminders>();
  bool _busy = false;

  TimeOfDay get _time => TimeOfDay(
        hour: _reminders.minutes ~/ 60,
        minute: _reminders.minutes % 60,
      );

  Future<void> _toggle(bool on) async {
    final messenger = ScaffoldMessenger.of(context);
    final denied = context.l10n.reminderDenied;
    setState(() => _busy = true);
    try {
      if (!on) {
        await _reminders.disable();
      } else if (!await _reminders.enable()) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(denied)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked == null) return;
    await _reminders.setTime(picked.hour * 60 + picked.minute);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: _reminders,
      builder: (context, _) {
        final enabled = _reminders.enabled;
        return Column(
          children: [
            SwitchListTile(
              secondary: const Icon(Icons.notifications_active_outlined),
              title: Text(l10n.reminderTitle),
              subtitle: Text(
                enabled
                    ? l10n.reminderOn(_time.format(context))
                    : l10n.reminderOff,
              ),
              value: enabled,
              onChanged: _busy ? null : _toggle,
            ),
            if (enabled) ...[
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.schedule_rounded),
                title: Text(l10n.reminderChangeTime),
                trailing: Text(_time.format(context)),
                onTap: _pickTime,
              ),
            ],
          ],
        );
      },
    );
  }
}
