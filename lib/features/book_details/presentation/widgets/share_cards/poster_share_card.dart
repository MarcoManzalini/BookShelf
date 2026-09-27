import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/utils/l10n_extension.dart';
import '../../../../../l10n/gen/app_localizations.dart';
import 'reading_share_data.dart';
import 'share_card_parts.dart';

const _cream = Color(0xFFF3ECDA);
const _ink = Color(0xFF33301F);

/// Template B: a poster in the color of the cover, up top; a dark ticket
/// with the session's figures floating over a cream half below.
class PosterShareCard extends StatelessWidget {
  const PosterShareCard({
    super.key,
    required this.data,
    this.tint,
    this.photo,
    this.place,
    this.quote,
  });

  final ReadingShareData data;

  /// Dominant color of the cover; the top half is painted with it.
  final Color? tint;

  /// Reading-spot photo, seen through the poster color.
  final ImageProvider? photo;
  final String? place;

  /// A line from the book, typed in by the reader; hidden when blank.
  final String? quote;

  static const _topHeight = 270.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final base = HSLColor.fromColor(tint ?? AppColors.accentDeep);
    final background = base
        .withLightness(0.33)
        .withSaturation(base.saturation.clamp(0.0, 0.55))
        .toColor();
    final spot = place?.trim();
    final trimmedQuote = quote?.trim();
    final attribution = [
      if (spot != null && spot.isNotEmpty) spot,
      'via BookShelf',
    ].join(' · ');

    return SizedBox.fromSize(
      size: shareCardSize,
      child: ColoredBox(
        color: _cream,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          fit: StackFit.expand,
          children: [
            SizedBox(
              height: _topHeight,
              child: ColoredBox(
                color: background,
                child: SharePhotoBackdrop(
                  photo: photo,
                  scrim: BoxDecoration(
                    color: background.withValues(alpha: 0.72),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const ShareBrand(),
                      const Spacer(),
                      Text(
                        DateFormat.yMMMEd(locale).format(data.day),
                        style: AppFonts.label(
                          size: 13,
                          weight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.shareNowReading,
                              style: AppFonts.label(
                                size: 12,
                                weight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              data.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.text(
                                size: 25,
                                weight: FontWeight.w800,
                                height: 1.12,
                                color: Colors.white,
                              ),
                            ),
                            if (data.author != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                data.author!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppFonts.text(
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Image.asset(
                        'assets/images/frog_reading.png',
                        width: 52,
                        fit: BoxFit.contain,
                        excludeFromSemantics: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  _Ticket(data: data, l10n: l10n),
                  if (trimmedQuote != null && trimmedQuote.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    // White reads better here than dark ink; it needs its
                    // own dark patch to sit on since the card is cream
                    // underneath, continuing the ticket above.
                    ShareQuote(
                      quote: trimmedQuote,
                      markColor: AppColors.accent,
                      background: shareInk,
                    ),
                  ],
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(
                        Icons.place_rounded,
                        size: 13,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          attribution,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.label(
                            size: 12,
                            weight: FontWeight.w700,
                            color: _ink.withValues(alpha: 0.7),
                          ),
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

/// The dark stub with the session's headline figure and the stat row,
/// punched with two notches so it reads as a ticket.
class _Ticket extends StatelessWidget {
  const _Ticket({required this.data, required this.l10n});

  final ReadingShareData data;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final duration = data.minutes == null
        ? null
        : durationParts(data.minutes!, l10n.shareUnitMin);
    final streak = data.streakDays;
    final progress = data.progress;
    final muted = Colors.white.withValues(alpha: 0.55);
    final stats = <({String value, String? unit, String label})>[
      if (duration != null && !data.heroIsMinutes)
        (
          value: duration.value,
          unit: duration.unit,
          label: l10n.shareLabelTime,
        ),
      if (data.pace != null)
        (
          value: '${data.pace}',
          unit: l10n.shareUnitPagesPerHour,
          label: l10n.shareLabelPace,
        ),
      if (progress != null)
        (
          value: '${(progress * 100).round()}',
          unit: '%',
          label: l10n.shareLabelBook,
        ),
      if (streak != null)
        (
          value: '$streak',
          unit: l10n.shareUnitDays(streak),
          label: l10n.shareLabelStreak,
        ),
    ];

    return Stack(
      clipBehavior: Clip.none,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: shareInk,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ShareHero(
                  value: '${data.heroValue}',
                  unit: data.heroIsMinutes
                      ? l10n.shareUnitMin
                      : (data.isOn(DateTime.now())
                          ? l10n.shareReadToday
                          : l10n.shareRead),
                  numberSize: 46,
                  unitSize: 15,
                  height: 40,
                ),
                if (stats.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const ColoredBox(
                    color: Colors.white24,
                    child: SizedBox(height: 1),
                  ),
                  const SizedBox(height: 14),
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
              ],
            ),
          ),
        ),
        const Positioned(top: 58, left: -9, child: _Notch()),
        const Positioned(top: 58, right: -9, child: _Notch()),
      ],
    );
  }
}

class _Notch extends StatelessWidget {
  const _Notch();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(color: _cream, shape: BoxShape.circle),
      child: SizedBox.square(dimension: 18),
    );
  }
}
