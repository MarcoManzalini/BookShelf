import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/l10n_extension.dart';
import '../../../library/domain/entities/user_book.dart';
import '../bloc/book_details_bloc.dart';

class ReadingProgressSection extends StatefulWidget {
  const ReadingProgressSection({super.key, required this.userBook});

  final UserBook userBook;

  @override
  State<ReadingProgressSection> createState() => _ReadingProgressSectionState();
}

class _ReadingProgressSectionState extends State<ReadingProgressSection> {
  double? _dragValue;

  Future<void> _editPage() async {
    final l10n = context.l10n;
    final bloc = context.read<BookDetailsBloc>();
    final total = widget.userBook.pageCount;
    final controller =
        TextEditingController(text: '${widget.userBook.currentPage}');
    final formKey = GlobalKey<FormState>();

    final page = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editCurrentPage),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.currentPage,
              suffixText: total == null ? null : '/ $total',
            ),
            validator: (value) {
              final n = int.tryParse(value ?? '');
              if (n == null || n < 0 || (total != null && n > total)) {
                return l10n.validationPageInvalid;
              }
              return null;
            },
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
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, int.parse(controller.text));
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (page != null) bloc.add(BookDetailsProgressChanged(page));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final book = widget.userBook;
    final total = book.pageCount;
    final current = _dragValue?.round() ?? book.currentPage;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    total != null
                        ? l10n.pageOfTotal(current, total)
                        : l10n.currentPageOnly(current),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (total != null && total > 0)
                  Text(
                    '${((current / total) * 100).round()}%',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                IconButton(
                  tooltip: l10n.editCurrentPage,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: _editPage,
                ),
              ],
            ),
            if (total != null && total > 0)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (current / total).clamp(0.0, 1.0),
                        minHeight: 8,
                      ),
                    ),
                    Slider(
                      value: current.clamp(0, total).toDouble(),
                      max: total.toDouble(),
                      onChanged: (v) => setState(() => _dragValue = v),
                      onChangeEnd: (v) {
                        setState(() => _dragValue = null);
                        context
                            .read<BookDetailsBloc>()
                            .add(BookDetailsProgressChanged(v.round()));
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
