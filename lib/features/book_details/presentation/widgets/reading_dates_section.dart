import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/l10n_extension.dart';
import '../../../library/domain/entities/user_book.dart';
import '../bloc/book_details_bloc.dart';

class ReadingDatesSection extends StatelessWidget {
  const ReadingDatesSection({super.key, required this.userBook});

  final UserBook userBook;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
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
      subtitle: Text(
        value == null
            ? l10n.notSet
            : DateFormat.yMMMd(Localizations.localeOf(context).toString())
                .format(value),
      ),
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
