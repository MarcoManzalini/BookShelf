import 'package:flutter/material.dart';

import '../../../../core/utils/cover_url.dart';
import '../../../../core/widgets/book_cover.dart';
import '../../domain/entities/user_book.dart';
import 'book_progress.dart';
import 'status_chip.dart';
import 'status_ribbon.dart';

class LibraryBookTile extends StatelessWidget {
  const LibraryBookTile({super.key, required this.book, required this.onTap});

  final UserBook book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Hero(
                    tag: 'cover_${book.id}',
                    child: BookCover(
                      url: book.book.coverUrl,
                      title: book.book.title,
                      author: book.book.authorsLabel,
                      width: 76,
                      height: 114,
                      size: CoverSize.medium,
                    ),
                  ),
                  Positioned(
                    top: -2,
                    right: 8,
                    child: StatusRibbon(status: book.status),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    if (book.book.authors.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        book.book.authorsLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    StatusChip(status: book.status),
                    const SizedBox(height: 10),
                    BookProgress(book: book),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
