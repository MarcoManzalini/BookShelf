import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/cover_url.dart';
import '../../../../core/widgets/book_cover.dart';
import '../../../../core/widgets/book_open_target.dart';
import '../../domain/entities/book.dart';
import 'rank_number.dart';

/// Horizontal strip of covers with title and author underneath. With
/// [ranked], each cover has its chart position beside it as a big number in
/// the cover's own color, half hidden behind it.
class BookRail extends StatelessWidget {
  const BookRail({
    super.key,
    required this.books,
    required this.onTap,
    this.ranked = false,
    this.showRating = false,
  });

  final List<Book> books;
  final ValueChanged<Book> onTap;
  final bool ranked;

  /// Adds the community rating and its vote count under the author.
  final bool showRating;

  static const coverWidth = 112.0;
  static const coverHeight = coverWidth * 1.5;
  static const height = coverWidth * 1.5 + 58;
  static const heightWithRating = height + 18;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: showRating ? heightWithRating : height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: books.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final book = books[index];
          final slot = ranked ? RankNumber.slotFor(index + 1) : 0.0;
          // Builder: the item's own context, so a tap captures its own cover
          // and not the first one of the whole list.
          return Builder(
            builder: (itemContext) => SizedBox(
              width: slot + coverWidth,
              child: InkWell(
                onTap: () {
                  BookOpenTarget.capture(itemContext);
                  onTap(book);
                },
                borderRadius: BorderRadius.circular(6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: coverHeight,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          if (ranked)
                            Positioned(
                              left: 0,
                              // Digits sit on the cover's bottom edge; the box
                              // below them is empty line height.
                              bottom: -RankNumber.fontSize * RankNumber.descent,
                              child: RankNumber(
                                rank: index + 1,
                                coverUrl: book.coverUrl,
                              ),
                            ),
                          Positioned(
                            left: slot,
                            child: BookOpenTarget(
                              url: book.coverUrl,
                              title: book.title,
                              author: book.authorsLabel,
                              size: CoverSize.large,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(46),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: BookCover(
                                  url: book.coverUrl,
                                  title: book.title,
                                  author: book.authorsLabel,
                                  size: CoverSize.large,
                                  width: coverWidth,
                                  height: coverHeight,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: EdgeInsets.only(left: slot),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontSize: 12.5),
                          ),
                          if (book.authors.isNotEmpty)
                            Text(
                              book.authorsLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(fontSize: 11),
                            ),
                          if (showRating && book.hasCommunityRating)
                            _RatingLine(book: book),
                        ],
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

/// "★ 4.8 (50)": the average and how many votes stand behind it.
class _RatingLine extends StatelessWidget {
  const _RatingLine({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          const Icon(Icons.star_rounded, size: 13, color: AppColors.accent),
          const SizedBox(width: 2),
          Flexible(
            child: Text(
              '${book.ratingAverage!.toStringAsFixed(1)} '
              '(${book.ratingsCount})',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
