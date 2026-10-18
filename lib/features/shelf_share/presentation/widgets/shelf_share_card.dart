import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/l10n_extension.dart';
import '../../../book_details/presentation/widgets/share_cards/share_card_parts.dart';
import '../../../library/presentation/widgets/shelf_color.dart';
import '../../../search/domain/entities/book.dart';

/// Story-shaped picture of a shelf, sent along with its link: name, book
/// count and a few covers. Drawn at [shareCardSize], exported at 3x.
class ShelfShareCard extends StatelessWidget {
  const ShelfShareCard({
    super.key,
    required this.shelfName,
    required this.books,
  });

  final String shelfName;
  final List<Book> books;

  /// Covers shown (two rows of three).
  static const maxCovers = 6;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final covers = books.take(maxCovers).toList();
    return SizedBox.fromSize(
      size: shareCardSize,
      child: ColoredBox(
        color: shareInk,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ShareBrand(),
              const SizedBox(height: 28),
              Container(
                width: 36,
                height: 6,
                decoration: BoxDecoration(
                  color: shelfColor(shelfName),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                shelfName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.text(
                  size: 30,
                  weight: FontWeight.w800,
                  height: 1.1,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.sharedShelfBookCount(books.length),
                style: AppFonts.label(size: 14, color: Colors.white70),
              ),
              const Spacer(),
              if (covers.isNotEmpty)
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2 / 3,
                  children: [
                    for (final book in covers)
                      ShareCover(
                        url: book.coverUrl,
                        title: book.title,
                        author: book.authors.firstOrNull,
                        height: 140,
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
