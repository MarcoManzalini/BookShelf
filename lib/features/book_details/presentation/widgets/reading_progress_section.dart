import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/l10n_extension.dart';
import '../../../../core/utils/minutes_text.dart';
import '../../../../core/widgets/text_input_dialog.dart';
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

  /// Upper bound for the slider. When the total page count is unknown,
  /// grows dynamically so the slider stays usable instead of disappearing.
  double _sliderMax(int? total, int current) {
    if (total != null && total > 0) return total.toDouble();
    if (current <= 0) return 100;
    return (((current / 50).ceil() + 1) * 50).toDouble();
  }

  Future<void> _editPage() async {
    final l10n = context.l10n;
    final bloc = context.read<BookDetailsBloc>();
    final audio = widget.userBook.isAudio;
    final total = widget.userBook.progressTotal;
    final current = widget.userBook.currentPage;
    int? read(String value) =>
        audio ? MinutesText.parse(value) : int.tryParse(value.trim());

    final page = await showTextInputDialog<int>(
      context,
      title: audio ? l10n.positionEdit : l10n.editCurrentPage,
      initialText: audio ? MinutesText.edit(current) : '$current',
      keyboardType: audio
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number,
      labelText: audio ? l10n.positionReached : l10n.currentPage,
      hintText: audio ? l10n.durationHint : null,
      suffixText:
          total == null ? null : '/ ${audio ? MinutesText.edit(total) : total}',
      validator: (value) {
        final n = read(value);
        if (n == null || n < 0) {
          return audio ? l10n.durationInvalid : l10n.validationPageInvalid;
        }
        if (total != null && n > total) {
          return audio ? l10n.positionInvalid : l10n.validationPageInvalid;
        }
        return null;
      },
      parse: read,
    );
    if (page != null) bloc.add(BookDetailsProgressChanged(page));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final book = widget.userBook;
    final total = book.progressTotal;
    // Books saved before the bookmark followed edition changes can be past
    // the end: never show more than the total.
    final saved =
        total != null && book.currentPage > total ? total : book.currentPage;
    final current = _dragValue?.round() ?? saved;
    String text(int value) =>
        book.isAudio ? MinutesText.format(l10n, value) : '$value';
    final sliderMax = _sliderMax(total, current);

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
                    book.isAudio
                        ? (total != null
                            ? l10n.positionOfTotal(text(current), text(total))
                            : text(current))
                        : total != null
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
                  tooltip:
                      book.isAudio ? l10n.positionEdit : l10n.editCurrentPage,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: _editPage,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Column(
                children: [
                  if (total != null && total > 0)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (current / total).clamp(0.0, 1.0),
                        minHeight: 8,
                      ),
                    ),
                  Slider(
                    value: current.clamp(0, sliderMax).toDouble(),
                    max: sliderMax,
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
