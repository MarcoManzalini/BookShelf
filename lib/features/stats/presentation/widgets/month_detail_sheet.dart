import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/l10n_extension.dart';
import '../../../../core/widgets/book_cover.dart';
import '../../../library/domain/entities/user_book.dart';
import '../../domain/entities/month_detail.dart';
import 'stat_tile.dart';

/// Bottom sheet with the exact numbers behind one bar of the "books per
/// month" chart: books finished that month plus the pages, time and active
/// days logged in it.
class MonthDetailSheet extends StatelessWidget {
  const MonthDetailSheet({super.key, required this.detail});

  final MonthDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final rawTitle = DateFormat.yMMMM(locale).format(detail.month);
    final title = rawTitle.isEmpty
        ? rawTitle
        : rawTitle[0].toUpperCase() + rawTitle.substring(1);
    final hours = detail.minutesRead / 60;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => SafeArea(
        top: false,
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: Text(l10n.recapOpenMonth),
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push(
                      AppRoutes.recap(detail.month.year, detail.month.month),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.9,
              children: [
                StatTile(
                  icon: Icons.menu_book_rounded,
                  value: '${detail.booksFinished.length}',
                  label: l10n.statsMonthBooksFinished,
                ),
                StatTile(
                  icon: Icons.auto_stories_rounded,
                  value: '${detail.pagesRead}',
                  label: l10n.statsMonthPagesRead,
                ),
                StatTile(
                  icon: Icons.schedule_rounded,
                  value: detail.minutesRead == 0
                      ? l10n.statsNoData
                      : l10n.statsHours(hours.toStringAsFixed(1)),
                  label: l10n.statsTimeRead,
                ),
                StatTile(
                  icon: Icons.local_fire_department_rounded,
                  value: '${detail.activeDays}',
                  label: l10n.statsMonthActiveDays,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              l10n.statsMonthBooksFinished,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (detail.booksFinished.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  l10n.statsMonthNoBooks,
                  style: AppFonts.text(
                    size: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              for (final book in detail.booksFinished) _BookRow(book: book),
          ],
        ),
      ),
    );
  }
}

class _BookRow extends StatelessWidget {
  const _BookRow({required this.book});

  final UserBook book;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final author = book.book.authors.join(', ');
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.of(context).pop();
        context.push(AppRoutes.bookDetails(book.id));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            BookCover(
              url: book.book.coverUrl,
              title: book.book.title,
              author: author,
              width: 36,
              height: 54,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.text(
                      size: 14,
                      weight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (author.isNotEmpty)
                    Text(
                      author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.label(
                        size: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
