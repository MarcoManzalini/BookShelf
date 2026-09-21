import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/cover_url.dart';
import '../../../../core/widgets/book_cover.dart';
import '../../../../core/widgets/book_open_target.dart';
import '../../domain/entities/book.dart';
import 'star_rating.dart';

/// Horizontal strip of wide cards: small cover, title, author and rating.
class NewArrivalsRail extends StatelessWidget {
  const NewArrivalsRail({super.key, required this.books, required this.onTap});

  final List<Book> books;
  final ValueChanged<Book> onTap;

  static const height = 118.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        // Room for the cards' shadows above and below.
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: books.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) =>
            _Card(book: books[index], onTap: () => onTap(books[index])),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.book, required this.onTap});

  final Book book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 268,
      child: Card(
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
                    size: CoverSize.medium,
                    width: 60,
                    height: 90,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      if (book.authors.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          book.authorsLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                      if (book.hasCommunityRating) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            StarRating(value: book.ratingAverage!),
                            const SizedBox(width: 6),
                            Text(
                              book.ratingAverage!.toStringAsFixed(1),
                              style: AppFonts.text(
                                size: 12,
                                weight: FontWeight.w800,
                                color: AppColors.accentDeep,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
