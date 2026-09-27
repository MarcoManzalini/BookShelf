import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/l10n_extension.dart';
import '../../../library/domain/entities/book_vibe.dart';
import '../../../library/domain/entities/user_book.dart';
import '../../../library/presentation/widgets/book_extras_ui.dart';
import '../bloc/book_details_bloc.dart';

/// How the book felt: up to three moods and the pace.
class VibeSection extends StatelessWidget {
  const VibeSection({super.key, required this.userBook});

  final UserBook userBook;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final bloc = context.read<BookDetailsBloc>();
    final chosen = userBook.moods;
    final full = chosen.length >= BookMood.maxPerBook;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.vibeMoodsHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final mood in BookMood.values)
              FilterChip(
                label: Text(mood.label(l10n)),
                selected: chosen.contains(mood),
                // Once three are picked, the others wait for one to go.
                onSelected: !chosen.contains(mood) && full
                    ? null
                    : (on) => bloc.add(
                          BookDetailsMoodsChanged(
                            on
                                ? [...chosen, mood]
                                : [
                                    for (final m in chosen)
                                      if (m != mood) m,
                                  ],
                          ),
                        ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(l10n.vibePace, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<ReadingPace>(
          showSelectedIcon: false,
          emptySelectionAllowed: true,
          segments: [
            for (final pace in ReadingPace.values)
              ButtonSegment(value: pace, label: Text(pace.label(l10n))),
          ],
          selected: {if (userBook.pace != null) userBook.pace!},
          onSelectionChanged: (selection) =>
              bloc.add(BookDetailsPaceChanged(selection.firstOrNull)),
        ),
      ],
    );
  }
}
