import 'package:flutter/material.dart';

import '../../../../core/widgets/book_cover.dart';
import '../../../../core/widgets/book_open_target.dart';
import '../../domain/entities/book.dart';
import 'add_to_library_button.dart';

class SearchResultTile extends StatelessWidget {
  const SearchResultTile({super.key, required this.book, required this.onTap});

  final Book book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = [
      if (book.authors.isNotEmpty) book.authorsLabel,
      if (book.publishedYear != null) '${book.publishedYear}',
    ].join(' · ');
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          BookOpenTarget.capture(context);
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              BookOpenTarget(
                url: book.coverUrl,
                title: book.title,
                author: book.authorsLabel,
                child: BookCover(
                  url: book.coverUrl,
                  title: book.title,
                  author: book.authorsLabel,
                  width: 56,
                  height: 84,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AddToLibraryButton(book: book),
            ],
          ),
        ),
      ),
    );
  }
}
