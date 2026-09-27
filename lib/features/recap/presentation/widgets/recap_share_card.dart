import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/l10n_extension.dart';
import '../../../book_details/presentation/widgets/share_cards/share_card_parts.dart';
import '../../domain/reading_recap.dart';

/// Story-shaped summary of a recap, drawn at [shareCardSize] and exported at
/// 3x (1080x1920) like the session cards.
class RecapShareCard extends StatelessWidget {
  const RecapShareCard({super.key, required this.recap, required this.title});

  final ReadingRecap recap;
  final String title;

  /// Covers shown in the strip (the rest would be too small to see).
  static const maxCovers = 5;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final number = NumberFormat.decimalPattern(locale);
    final hours = recap.minutesRead / 60;
    final covers = <String, RecapRead>{
      for (final read in recap.finished) read.book.id: read,
    }.values.take(maxCovers).toList();

    Widget stat(String value, String label) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: AppFonts.text(
                  size: 40,
                  weight: FontWeight.w800,
                  height: 1,
                  letterSpacing: -1,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 2,
              style: AppFonts.label(size: 12, color: Colors.white70),
            ),
          ],
        );

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
              Text(
                title,
                maxLines: 2,
                style: AppFonts.text(
                  size: 28,
                  weight: FontWeight.w800,
                  height: 1.1,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: stat(
                      number.format(recap.finished.length),
                      l10n.recapBooksLabel(recap.finished.length),
                    ),
                  ),
                  Expanded(
                    child: stat(
                      number.format(recap.pagesRead),
                      l10n.recapPagesLabel,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: recap.minutesRead >= 60
                        ? stat(hours.toStringAsFixed(0), l10n.recapHoursLabel)
                        : stat(
                            number.format(recap.minutesRead),
                            l10n.recapMinutesLabel,
                          ),
                  ),
                  Expanded(
                    child: stat(
                      number.format(recap.longestStreak),
                      l10n.recapStreakLabel(recap.longestStreak),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (covers.isNotEmpty)
                SizedBox(
                  height: 120,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final read in covers)
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: ShareCover(
                              url: read.book.book.coverUrl,
                              title: read.book.book.title,
                              author: read.book.book.authors.firstOrNull,
                              height: 110,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              if (recap.topRated != null) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.recapTopRated.toUpperCase(),
                  style: AppFonts.label(
                    size: 11,
                    weight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  recap.topRated!.book.book.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.text(
                    size: 17,
                    weight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'via BookShelf',
                style: AppFonts.label(size: 11, color: Colors.white38),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
