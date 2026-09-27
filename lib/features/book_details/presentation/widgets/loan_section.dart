import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/l10n_extension.dart';
import '../../../library/domain/entities/book_loan.dart';
import '../../../library/domain/entities/user_book.dart';
import '../bloc/book_details_bloc.dart';

String _day(BuildContext context, DateTime date) =>
    DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(date);

/// Who has the book (or whose it is), since when and until when.
class LoanSection extends StatelessWidget {
  const LoanSection({super.key, required this.userBook, this.now});

  final UserBook userBook;

  /// Today, for the overdue badge; tests pass a fixed day.
  final DateTime? now;

  Future<void> _edit(BuildContext context, LoanKind kind) async {
    final bloc = context.read<BookDetailsBloc>();
    final loan = await showDialog<BookLoan>(
      context: context,
      builder: (_) => _LoanDialog(kind: kind, initial: userBook.loan),
    );
    if (loan != null) bloc.add(BookDetailsLoanChanged(loan));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final loan = userBook.loan;
    if (loan == null) {
      return Wrap(
        spacing: 8,
        children: [
          TextButton.icon(
            icon: const Icon(Icons.north_east_rounded, size: 18),
            label: Text(l10n.loanLend),
            onPressed: () => _edit(context, LoanKind.lent),
          ),
          TextButton.icon(
            icon: const Icon(Icons.south_west_rounded, size: 18),
            label: Text(l10n.loanBorrow),
            onPressed: () => _edit(context, LoanKind.borrowed),
          ),
        ],
      );
    }
    final overdue = loan.isOverdue(now ?? DateTime.now());
    final due = loan.due;
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              loan.kind == LoanKind.lent
                  ? Icons.north_east_rounded
                  : Icons.south_west_rounded,
            ),
            title: Text(
              loan.kind == LoanKind.lent
                  ? l10n.loanLentTo(loan.person)
                  : l10n.loanBorrowedFrom(loan.person),
            ),
            subtitle: Text(
              [
                l10n.loanSince(_day(context, loan.since)),
                if (due != null) l10n.loanDue(_day(context, due)),
              ].join('\n'),
            ),
            isThreeLine: due != null,
            trailing: IconButton(
              tooltip: l10n.loanEdit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _edit(context, loan.kind),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
            child: Row(
              children: [
                if (overdue)
                  Chip(
                    avatar: Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                    label: Text(l10n.loanOverdue),
                    backgroundColor: theme.colorScheme.errorContainer,
                    labelStyle: TextStyle(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                const Spacer(),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.keyboard_return_rounded, size: 18),
                  label: Text(l10n.loanReturned),
                  onPressed: () => context
                      .read<BookDetailsBloc>()
                      .add(const BookDetailsLoanChanged(null)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoanDialog extends StatefulWidget {
  const _LoanDialog({required this.kind, required this.initial});

  final LoanKind kind;
  final BookLoan? initial;

  @override
  State<_LoanDialog> createState() => _LoanDialogState();
}

class _LoanDialogState extends State<_LoanDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _person = TextEditingController(text: widget.initial?.person);
  late DateTime _since = widget.initial?.since ?? _today;
  late DateTime? _due = widget.initial?.due;

  static DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _person.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lent = widget.kind == LoanKind.lent;
    final due = _due;
    return AlertDialog(
      title: Text(lent ? l10n.loanLend : l10n.loanBorrow),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _person,
              autofocus: widget.initial == null,
              maxLength: BookLoan.maxPersonLength,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: lent ? l10n.loanPersonLent : l10n.loanPersonBorrowed,
                counterText: '',
              ),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? l10n.validationRequired : null,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_rounded),
              title: Text(l10n.loanSinceLabel),
              subtitle: Text(_day(context, _since)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _since,
                  firstDate: DateTime(1900),
                  lastDate: _today,
                );
                if (picked != null) setState(() => _since = picked);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_available_rounded),
              title: Text(l10n.loanDueLabel),
              subtitle:
                  Text(due == null ? l10n.loanDueNone : _day(context, due)),
              trailing: due == null
                  ? null
                  : IconButton(
                      tooltip: l10n.clear,
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => setState(() => _due = null),
                    ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: due ?? _since.add(const Duration(days: 30)),
                  firstDate: _since,
                  lastDate: DateTime(_today.year + 5),
                );
                if (picked != null) setState(() => _due = picked);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final due = _due;
            Navigator.pop(
              context,
              BookLoan(
                kind: widget.kind,
                person: _person.text.trim(),
                since: _since,
                due: due != null && due.isBefore(_since) ? null : due,
              ),
            );
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
