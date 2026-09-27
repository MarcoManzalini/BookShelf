import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/utils/l10n_extension.dart';
import 'reading_share_data.dart';
import 'share_card_parts.dart';

/// Template C: the photo of the reading spot fills the card, the numbers sit
/// on a dark fade at the bottom and the mascot is stuck on a corner.
class PhotoShareCard extends StatelessWidget {
  const PhotoShareCard({
    super.key,
    required this.data,
    this.tint,
    this.photo,
    this.place,
    this.quote,
  });

  final ReadingShareData data;
  final Color? tint;

  /// The picture; without one the card falls back to a soft cover-colored fade.
  final ImageProvider? photo;
  final String? place;

  /// A line from the book, typed in by the reader; hidden when blank.
  final String? quote;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final spot = place?.trim();
    final duration = data.minutes == null
        ? null
        : durationParts(data.minutes!, l10n.shareUnitMin);
    final streak = data.streakDays;
    final facts = <String>[
      if (duration != null && !data.heroIsMinutes)
        [duration.value, if (duration.unit != null) duration.unit!].join(' '),
      if (data.pace != null) '${data.pace} ${l10n.shareUnitPagesPerHour}',
      if (streak != null) l10n.sharePillStreak(streak),
    ];
    final details = [
      if (data.author != null) data.author!,
      DateFormat.MMMEd(locale).format(data.day),
    ].join(' · ');
    final trimmedQuote = quote?.trim();

    return SizedBox.fromSize(
      size: shareCardSize,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _Backdrop(tint: tint, photo: photo),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: ShareBrand(size: 18),
                      ),
                    ),
                    const Spacer(),
                    Transform.rotate(
                      angle: -4 * math.pi / 180,
                      child: Image.asset(
                        'assets/images/frog_sticker.png',
                        width: 92,
                        excludeFromSemantics: true,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                ShareHero(
                  value: '${data.heroValue}',
                  unit: data.heroIsMinutes
                      ? l10n.shareUnitMin
                      : l10n.shareUnitPages,
                  numberSize: 96,
                  unitSize: 19,
                  height: 84,
                ),
                if (facts.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _Facts(facts: facts),
                ],
                if (trimmedQuote != null && trimmedQuote.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  ShareQuote(
                    quote: trimmedQuote,
                    // Its own patch of dark, so it reads regardless of how
                    // bright the photo underneath happens to be.
                    background: photo == null
                        ? null
                        : Colors.black.withValues(alpha: 0.32),
                  ),
                ],
                const SizedBox(height: 14),
                const ColoredBox(
                  color: Colors.white24,
                  child: SizedBox(height: 1),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    ShareCover(
                      url: data.coverUrl,
                      title: data.title,
                      author: data.author,
                      height: 54,
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
                              size: 15,
                              weight: FontWeight.w800,
                              height: 1.15,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            details,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.text(
                              size: 12,
                              color: Colors.white70,
                            ),
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
    );
  }
}

/// "52 min • 54 p/h • 5-day streak", dots in the accent color.
class _Facts extends StatelessWidget {
  const _Facts({required this.facts});

  final List<String> facts;

  @override
  Widget build(BuildContext context) {
    final style = AppFonts.text(
      size: 14,
      weight: FontWeight.w700,
      color: Colors.white,
    );
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, fact) in facts.indexed) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 9),
                child: SizedBox.square(
                  dimension: 5,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            Text(fact, style: style),
          ],
        ],
      ),
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.tint, required this.photo});

  final Color? tint;
  final ImageProvider? photo;

  @override
  Widget build(BuildContext context) {
    final photo = this.photo;
    final Widget base;
    if (photo != null) {
      base = Image(image: photo, fit: BoxFit.cover);
    } else {
      final hsl = HSLColor.fromColor(tint ?? AppColors.accent);
      base = DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              hsl.withLightness(0.66).withSaturation(0.3).toColor(),
              hsl.withLightness(0.5).withSaturation(0.25).toColor(),
            ],
          ),
        ),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        base,
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x33000000),
                Color(0x00000000),
                Color(0xE6161619),
                Color(0xFA161619),
              ],
              stops: [0, 0.3, 0.68, 1],
            ),
          ),
        ),
      ],
    );
  }
}
