import 'package:flutter/material.dart';

import '../../../../core/widgets/book_cover.dart';
import '../../../../core/widgets/book_open_target.dart';
import '../../../search/domain/entities/book.dart';

/// Horizontal strip of covers with title and author underneath.
class RelatedBooksRow extends StatelessWidget {
  const RelatedBooksRow({super.key, required this.books, required this.onTap});

  final List<Book> books;
  final ValueChanged<Book> onTap;

  static const _coverWidth = 104.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 232,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        // Items keep the page gutter on the left and scroll out to the screen
        // edge on the right instead of being clipped at the gutter.
        clipBehavior: Clip.none,
        itemCount: books.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final book = books[index];
          return Builder(
            builder: (itemContext) => SizedBox(
              width: _coverWidth,
              child: InkWell(
                onTap: () {
                  BookOpenTarget.capture(itemContext);
                  onTap(book);
                },
                borderRadius: BorderRadius.circular(4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BookOpenTarget(
                      url: book.coverUrl,
                      title: book.title,
                      author: book.authorsLabel,
                      child: BookCover(
                        url: book.coverUrl,
                        title: book.title,
                        author: book.authorsLabel,
                        width: _coverWidth,
                        height: _coverWidth * 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: 13,
                        height: 1.2,
                      ),
                    ),
                    if (book.authors.isNotEmpty)
                      Text(
                        book.authorsLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
