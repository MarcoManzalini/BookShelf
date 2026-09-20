import 'package:flutter/material.dart';

import '../../../../core/utils/cover_url.dart';
import '../../../../core/widgets/book_cover.dart';
import '../../domain/entities/user_book.dart';
import 'book_progress.dart';
import 'status_chip.dart';

class LibraryBookGridItem extends StatelessWidget {
  const LibraryBookGridItem({
    super.key,
    required this.book,
    required this.onTap,
  });

  final UserBook book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Hero(
              tag: 'cover_${book.id}',
              child: SizedBox.expand(
                child: BookCover(
                  url: book.book.coverUrl,
                  size: CoverSize.large,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            book.book.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          if (book.book.authors.isNotEmpty)
            Text(
              book.book.authorsLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 6),
          StatusChip(status: book.status),
          const SizedBox(height: 6),
          BookProgress(book: book, showLabel: false),
        ],
      ),
    );
  }
}
