import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/l10n_extension.dart';
import '../../../../core/utils/minutes_text.dart';
import '../../../../core/widgets/text_input_dialog.dart';
import '../../../library/domain/entities/book_format.dart';
import '../../../library/domain/entities/user_book.dart';
import '../../../library/presentation/widgets/book_extras_ui.dart';
import '../bloc/book_details_bloc.dart';

/// Print, ebook or audiobook; an audiobook also has a length in minutes.
class BookFormatSection extends StatelessWidget {
  const BookFormatSection({super.key, required this.userBook});

  final UserBook userBook;

  Future<void> _editDuration(BuildContext context) async {
    final l10n = context.l10n;
    final bloc = context.read<BookDetailsBloc>();
    final current = userBook.durationMinutes;
    final minutes = await showTextInputDialog<int>(
      context,
      title: l10n.durationTitle,
      initialText: current == null ? '' : MinutesText.edit(current),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      labelText: l10n.durationLabel,
      hintText: l10n.durationHint,
      validator: (value) {
        final n = MinutesText.parse(value);
        return (n == null || n <= 0) ? l10n.durationInvalid : null;
      },
      parse: MinutesText.parse,
    );
    if (minutes != null) bloc.add(BookDetailsDurationChanged(minutes));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final duration = userBook.durationMinutes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<BookFormat>(
          showSelectedIcon: false,
          segments: [
            for (final format in BookFormat.values)
              ButtonSegment(
                value: format,
                icon: Icon(format.icon, size: 18),
                label: Text(format.label(l10n)),
              ),
          ],
          selected: {userBook.format},
          onSelectionChanged: (selection) => context
              .read<BookDetailsBloc>()
              .add(BookDetailsFormatChanged(selection.first)),
        ),
        if (userBook.isAudio)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.timelapse_rounded),
            title: Text(l10n.durationTitle),
            subtitle: Text(
              duration == null
                  ? l10n.durationSet
                  : MinutesText.format(l10n, duration),
            ),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () => _editDuration(context),
          ),
      ],
    );
  }
}
