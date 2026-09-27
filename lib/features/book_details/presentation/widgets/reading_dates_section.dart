import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/l10n_extension.dart';
import '../../../library/domain/entities/book_read.dart';
import '../../../library/domain/entities/reading_status.dart';
import '../../../library/domain/entities/user_book.dart';
import '../bloc/book_details_bloc.dart';

String _formatDay(BuildContext context, DateTime date) =>
    DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(date);

/// Dates of the current read, plus the earlier reads of a book read more
/// than once.
class ReadingDatesSection extends StatelessWidget {
  const ReadingDatesSection({super.key, required this.userBook});

  final UserBook userBook;

  Future<void> _confirmReread(BuildContext context) async {
    final l10n = context.l10n;
    final bloc = context.read<BookDetailsBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.rereadTitle),
        content: Text(l10n.rereadMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.rereadButton),
          ),
        ],
      ),
    );
    if (confirmed ?? false) bloc.add(const BookDetailsRereadStarted());
  }

  Future<void> _addPastRead(BuildContext context) async {
    final bloc = context.read<BookDetailsBloc>();
    final read = await showDialog<BookRead>(
      context: context,
      builder: (_) => const _PastReadDialog(),
    );
    if (read != null) bloc.add(BookDetailsPastReadAdded(read));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    // Newest first; reads without a date at the end.
    final past = [...userBook.pastReads]..sort((a, b) {
        final fa = a.finishedAt;
        final fb = b.finishedAt;
        if (fa == null) return fb == null ? 0 : 1;
        if (fb == null) return -1;
        return fb.compareTo(fa);
      });
    final count = userBook.readCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Column(
            children: [
              _DateTile(
                icon: Icons.play_circle_outline_rounded,
                label: l10n.startedOn,
                date: userBook.startedAt,
                field: ReadingDateField.startedAt,
              ),
              const Divider(height: 1),
              _DateTile(
                icon: Icons.flag_outlined,
                label: l10n.finishedOn,
                date: userBook.finishedAt,
                field: ReadingDateField.finishedAt,
              ),
            ],
          ),
        ),
        if (count > 1 || past.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.pastReadsTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (count > 0)
                Text(
                  l10n.readCount(count),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                for (final (i, read) in past.indexed) ...[
                  if (i > 0) const Divider(height: 1),
                  _PastReadTile(read: read),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            if (userBook.status == ReadingStatus.read)
              TextButton.icon(
                icon: const Icon(Icons.replay_rounded, size: 18),
                label: Text(l10n.rereadButton),
                onPressed: () => _confirmReread(context),
              ),
            TextButton.icon(
              icon: const Icon(Icons.history_rounded, size: 18),
              label: Text(l10n.pastReadAdd),
              onPressed: () => _addPastRead(context),
            ),
          ],
        ),
      ],
    );
  }
}

class _PastReadTile extends StatelessWidget {
  const _PastReadTile({required this.read});

  final BookRead read;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final started = read.startedAt;
    final finished = read.finishedAt;
    return ListTile(
      leading: const Icon(Icons.check_circle_outline_rounded),
      title: Text(
        finished == null
            ? l10n.pastReadUndated
            : l10n.pastReadFinished(_formatDay(context, finished)),
      ),
      subtitle: started == null
          ? null
          : Text('${l10n.startedOn} ${_formatDay(context, started)}'),
      trailing: IconButton(
        tooltip: l10n.pastReadRemove,
        icon: const Icon(Icons.close_rounded),
        onPressed: () => context
            .read<BookDetailsBloc>()
            .add(BookDetailsPastReadRemoved(read)),
      ),
    );
  }
}

/// Asks for the dates of an earlier read; both are optional, but the end
/// cannot come before the start.
class _PastReadDialog extends StatefulWidget {
  const _PastReadDialog();

  @override
  State<_PastReadDialog> createState() => _PastReadDialogState();
}

class _PastReadDialogState extends State<_PastReadDialog> {
  DateTime? _started;
  DateTime? _finished;

  bool get _valid =>
      _started == null || _finished == null || !_finished!.isBefore(_started!);

  Future<DateTime?> _pick(DateTime? initial) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return showDatePicker(
      context: context,
      initialDate: initial ?? today,
      firstDate: DateTime(1900),
      lastDate: today,
      initialEntryMode: DatePickerEntryMode.input,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String label(DateTime? date) =>
        date == null ? l10n.notSet : _formatDay(context, date);
    return AlertDialog(
      title: Text(l10n.pastReadDialogTitle),
      contentPadding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.play_circle_outline_rounded),
            title: Text(l10n.startedOn),
            subtitle: Text(label(_started)),
            onTap: () async {
              final picked = await _pick(_started ?? _finished);
              if (picked != null) setState(() => _started = picked);
            },
          ),
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: Text(l10n.finishedOn),
            subtitle: Text(label(_finished)),
            onTap: () async {
              final picked = await _pick(_finished ?? _started);
              if (picked != null) setState(() => _finished = picked);
            },
          ),
          if (!_valid)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l10n.pastReadDateInvalid,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
          onPressed: _valid
              ? () => Navigator.pop(
                    context,
                    BookRead(startedAt: _started, finishedAt: _finished),
                  )
              : null,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.icon,
    required this.label,
    required this.date,
    required this.field,
  });

  final IconData icon;
  final String label;
  final DateTime? date;
  final ReadingDateField field;

  Future<void> _pick(BuildContext context) async {
    final bloc = context.read<BookDetailsBloc>();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: date ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year, now.month, now.day),
      initialEntryMode: DatePickerEntryMode.input,
    );
    if (picked != null) bloc.add(BookDetailsDateChanged(field, picked));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final value = date;
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value == null ? l10n.notSet : _formatDay(context, value)),
      trailing: value == null
          ? null
          : IconButton(
              tooltip: l10n.clear,
              icon: const Icon(Icons.close_rounded),
              onPressed: () => context
                  .read<BookDetailsBloc>()
                  .add(BookDetailsDateChanged(field, null)),
            ),
      onTap: () => _pick(context),
    );
  }
}
