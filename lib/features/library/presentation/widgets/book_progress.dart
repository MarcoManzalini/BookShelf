import 'package:flutter/material.dart';

import '../../../../core/utils/l10n_extension.dart';
import '../../domain/entities/reading_status.dart';
import '../../domain/entities/user_book.dart';

/// Linear progress for books being read; renders nothing otherwise.
class BookProgress extends StatelessWidget {
  const BookProgress({super.key, required this.book, this.showLabel = true});

  final UserBook book;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    if (book.status != ReadingStatus.reading) return const SizedBox.shrink();
    final total = book.pageCount;
    final progress = book.progress;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (progress != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: progress, minHeight: 6),
          ),
        if (showLabel) ...[
          const SizedBox(height: 4),
          Text(
            total != null
                ? context.l10n.pagesProgress(book.currentPage, total)
                : context.l10n.currentPageOnly(book.currentPage),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ],
    );
  }
}
