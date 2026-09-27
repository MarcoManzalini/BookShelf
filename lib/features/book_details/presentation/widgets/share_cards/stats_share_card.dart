import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/utils/l10n_extension.dart';
import 'reading_share_data.dart';
import 'share_card_parts.dart';

/// Template A: dark card led by the number, with where in the book the
/// session took the reader and the figures underneath.
class StatsShareCard extends StatelessWidget {
  const StatsShareCard({
    super.key,
    required this.data,
    this.place,
    this.photo,
    this.quote,
  });

  final ReadingShareData data;
  final String? place;

  /// Reading-spot photo, faded into the dark card from the top.
  final ImageProvider? photo;

  /// A line from the book, typed in by the reader; hidden when blank.
  final String? quote;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final spot = place?.trim();
    final progress = data.progress;
    final before = data.progressBefore;
    final from = data.startPage;
    final duration = data.minutes == null
        ? null
        : durationParts(data.minutes!, l10n.shareUnitMin);
    final streak = data.streakDays;
    final stats = <({String value, String? unit, String label})>[
      if (duration != null && !data.heroIsMinutes)
        (
          value: duration.value,
          unit: duration.unit,
          label: l10n.shareLabelTime
        ),
      if (data.pace != null)
        (
          value: '${data.pace}',
          unit: l10n.shareUnitPagesPerHour,
          label: l10n.shareLabelPace,
        ),
      if (streak != null)
        (
          value: '$streak',
          unit: l10n.shareUnitDays(streak),
          label: l10n.shareLabelStreak,
        ),
    ];
    final muted = Colors.white.withValues(alpha: 0.55);
    final week = data.weekPages;
    final weekLabels = week == null
        ? const <String>[]
        : [
            for (var i = 6; i >= 0; i--)
              DateFormat.EEEE(locale)
                  .format(data.day.subtract(Duration(days: i)))
                  .substring(0, 1)
                  .toUpperCase(),
          ];
    final trimmedQuote = quote?.trim();

    return SizedBox.fromSize(
      size: shareCardSize,
      child: ColoredBox(
        color: shareInk,
        child: Stack(
          fit: StackFit.expand,
          children: [
            SharePhotoBackdrop(
              photo: photo,
              scrim: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x8018181B),
                    Color(0xE018181B),
                    Color(0xFF18181B),
                  ],
                  stops: [0, 0.5, 0.72],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const ShareBrand(),
                      const Spacer(),
                      Text(
                        DateFormat.yMMMEd(locale).format(data.day),
                        style: AppFonts.label(size: 13, color: muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.shareSessionLabel,
                    style: AppFonts.label(
                      size: 12,
                      weight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ShareHero(
                    value: '${data.heroValue}',
                    unit: data.heroIsMinutes
                        ? l10n.shareUnitMin
                        : l10n.shareUnitPages,
                    numberSize: 112,
                    unitSize: 21,
                    height: 104,
                  ),
                  if (progress != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          from == null
                              ? l10n.sharePageAt(data.endPage!)
                              : l10n.shareRange(from, data.endPage!),
                          style: AppFonts.text(
                            size: 14,
                            weight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          l10n.shareOfTotal(
                            (progress * 100).round(),
                            data.totalPages!,
                          ),
                          style: AppFonts.label(size: 14, color: muted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _SessionBar(before: before ?? progress, upTo: progress),
                  ],
                  if (trimmedQuote != null && trimmedQuote.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    ShareQuote(
                      quote: trimmedQuote,
                      // The scrim above a user photo isn't fully opaque yet
                      // this high up the card: give the text its own patch
                      // of dark so it reads whatever the photo looks like.
                      background: photo == null
                          ? null
                          : Colors.black.withValues(alpha: 0.32),
                    ),
                  ],
                  const Spacer(),
                  if (week != null) ...[
                    Text(
                      l10n.shareThisWeek,
                      style: AppFonts.label(
                        size: 12,
                        weight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: muted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ShareWeekBars(values: week, labels: weekLabels),
                    const SizedBox(height: 6),
                  ],
                  const ColoredBox(
                    color: Color(0xFF3A3A40),
                    child: SizedBox(height: 1),
                  ),
                  if (stats.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final s in stats)
                          Expanded(
                            child: ShareStatColumn(
                              value: s.value,
                              unit: s.unit,
                              label: s.label,
                              mutedColor: muted,
                            ),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ShareCover(
                        url: data.coverUrl,
                        title: data.title,
                        author: data.author,
                        height: 58,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              data.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.text(
                                size: 16,
                                weight: FontWeight.w800,
                                height: 1.15,
                                color: Colors.white,
                              ),
                            ),
                            if (data.author != null)
                              Text(
                                data.author!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppFonts.text(size: 13, color: muted),
                              ),
                            if (spot != null && spot.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              SharePlace(place: spot),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Where the book stood before (grey), what this session added (orange) and
/// what is left (dark).
class _SessionBar extends StatelessWidget {
  const _SessionBar({required this.before, required this.upTo});

  final double before;
  final double upTo;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 10,
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          // A session too small to see still gets a visible mark.
          final segment = ((upTo - before) * w).clamp(12.0, w);
          final start = (before * w).clamp(0.0, w - segment);
          return Stack(
            children: [
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFF2B2B31),
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                width: start + 5,
                top: 0,
                bottom: 0,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFF5A5A62),
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                  ),
                ),
              ),
              Positioned(
                left: start,
                width: segment,
                top: 0,
                bottom: 0,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
