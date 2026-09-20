import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/cover_url.dart';
import '../../../../core/widgets/book_cover.dart';
import '../../domain/entities/user_book.dart';
import 'book_progress.dart';
import 'status_chip.dart';
import 'status_ribbon.dart';

/// A book standing on a shelf: the plank spans the whole cell so neighbouring
/// items read as one shelf.
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
    final walnut = theme.brightness == Brightness.dark
        ? AppColors.walnutDark
        : AppColors.walnutLight;

    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: AspectRatio(
                  aspectRatio: BookCover.aspectRatio,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: Hero(
                          tag: 'cover_${book.id}',
                          child: BookCover(
                            url: book.book.coverUrl,
                            title: book.book.title,
                            author: book.book.authorsLabel,
                            size: CoverSize.large,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                      ),
                      Positioned(
                        top: -2,
                        right: 8,
                        child: StatusRibbon(status: book.status, width: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            height: 9,
            decoration: BoxDecoration(
              color: walnut,
              border: Border(
                top: BorderSide(color: AppColors.brass.withAlpha(140)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(50),
                  blurRadius: 6,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
          // Fixed height keeps every plank on the same line across a row.
          SizedBox(
            height: 112,
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(height: 1.2),
                  ),
                  if (book.book.authors.isNotEmpty)
                    Text(
                      book.book.authorsLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  const SizedBox(height: 8),
                  StatusChip(status: book.status),
                  const SizedBox(height: 6),
                  BookProgress(book: book, showLabel: false),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
