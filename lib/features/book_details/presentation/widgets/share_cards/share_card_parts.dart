import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/book_cover.dart';

/// Size every share card is drawn at (9:16, story-shaped); exported at 3x,
/// so 1080x1920.
const shareCardSize = Size(360, 640);

const _inkCard = Color(0xFF18181B);
const shareInk = _inkCard;

/// "1h05" or "52": the value of a duration, and its unit when it is minutes.
({String value, String? unit}) durationParts(int minutes, String minUnit) {
  if (minutes < 60) return (value: '$minutes', unit: minUnit);
  return (
    value: '${minutes ~/ 60}h${(minutes % 60).toString().padLeft(2, '0')}',
    unit: null,
  );
}

/// The three-books BookShelf mark plus the name.
class ShareBrand extends StatelessWidget {
  const ShareBrand({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    Widget bar(double height, Color color) => Container(
          width: size * 0.22,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(size * 0.07),
          ),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: size,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              bar(size * 0.85, AppColors.accent),
              SizedBox(width: size * 0.09),
              bar(size, Colors.white),
              SizedBox(width: size * 0.09),
              bar(size * 0.7, AppColors.accent),
            ],
          ),
        ),
        SizedBox(width: size * 0.4),
        Text(
          'BookShelf',
          style: AppFonts.text(
            size: size * 0.72,
            weight: FontWeight.w800,
            height: 1.1,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

/// A big number with its unit next to it, scaled down to fit [maxWidth].
class ShareHero extends StatelessWidget {
  const ShareHero({
    super.key,
    required this.value,
    required this.unit,
    required this.numberSize,
    required this.unitSize,
    this.unitColor = Colors.white,
    this.height,
    this.unitBelow = false,
  });

  final String value;
  final String unit;
  final double numberSize;
  final double unitSize;
  final Color unitColor;
  final double? height;

  /// Puts the unit under the number instead of beside it.
  final bool unitBelow;

  @override
  Widget build(BuildContext context) {
    final number = Text(
      value,
      style: AppFonts.text(
        size: numberSize,
        weight: FontWeight.w800,
        height: 1,
        letterSpacing: -numberSize * 0.04,
        color: Colors.white,
      ),
    );
    final unitText = Text(
      unit,
      style: AppFonts.text(
        size: unitSize,
        weight: FontWeight.w700,
        height: 1.1,
        color: unitColor,
      ),
    );
    return SizedBox(
      height: height,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: unitBelow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [number, unitText],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                mainAxisSize: MainAxisSize.min,
                children: [
                  number,
                  SizedBox(width: unitSize * 0.5),
                  unitText,
                ],
              ),
      ),
    );
  }
}

/// Small cover of the book, with its real proportions.
class ShareCover extends StatelessWidget {
  const ShareCover({
    super.key,
    required this.url,
    required this.title,
    required this.author,
    required this.height,
  });

  final String? url;
  final String title;
  final String? author;
  final double height;

  @override
  Widget build(BuildContext context) {
    return NaturalBookCover(
      url: url,
      height: height,
      title: title,
      author: author,
      borderRadius: 3,
    );
  }
}

/// "📍 Place" in the accent color.
class SharePlace extends StatelessWidget {
  const SharePlace({super.key, required this.place, this.color});

  final String place;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.place_rounded, size: 13, color: AppColors.accent),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            place,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.label(
              size: 12,
              weight: FontWeight.w600,
              color: color ?? Colors.white70,
            ),
          ),
        ),
      ],
    );
  }
}

/// One figure in a stat row: a value (with an optional unit) over a small
/// caps label, e.g. "54 p/h" over "PACE".
class ShareStatColumn extends StatelessWidget {
  const ShareStatColumn({
    super.key,
    required this.value,
    required this.label,
    this.unit,
    this.valueColor = Colors.white,
    this.unitColor = Colors.white70,
    required this.mutedColor,
  });

  final String value;
  final String? unit;
  final String label;
  final Color valueColor;
  final Color unitColor;

  /// Color of the label underneath.
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: AppFonts.text(
                  size: 24,
                  weight: FontWeight.w800,
                  height: 1.1,
                  color: valueColor,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 3),
                Text(
                  unit!,
                  style: AppFonts.text(
                    size: 13,
                    weight: FontWeight.w600,
                    color: unitColor,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppFonts.label(
            size: 11,
            weight: FontWeight.w700,
            letterSpacing: 0.8,
            color: mutedColor,
          ),
        ),
      ],
    );
  }
}

/// A user-picked line from the book, opened and closed with a quotation
/// mark. Meant to be skipped entirely (by the caller) when there is no quote
/// to show.
class ShareQuote extends StatelessWidget {
  const ShareQuote({
    super.key,
    required this.quote,
    this.color = Colors.white,
    this.markColor = AppColors.accent,
    this.background,
  });

  final String quote;

  /// Text color; pick one that reads against the card it sits on (light
  /// text on a dark card, dark ink on a light one).
  final Color color;
  final Color markColor;

  /// A backdrop behind the text, for cards where a user photo can sit
  /// underneath and the exact background is otherwise unknown.
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final markStyle = AppFonts.text(
      size: 30,
      weight: FontWeight.w800,
      height: 0.6,
      color: markColor,
    );
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('“', style: markStyle),
        const SizedBox(width: 6),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: quote,
                  style: AppFonts.text(
                    size: 15,
                    weight: FontWeight.w600,
                    style: FontStyle.italic,
                    height: 1.32,
                    color: color,
                  ),
                ),
                // The closing mark matches the opening one's size and weight.
                TextSpan(text: '”', style: markStyle),
              ],
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
    final backdrop = background;
    if (backdrop == null) return content;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backdrop,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: content,
      ),
    );
  }
}

/// A week of small bars (oldest to newest, left to right), the last one
/// (today, or the session's day) picked out in the accent color.
class ShareWeekBars extends StatelessWidget {
  const ShareWeekBars({
    super.key,
    required this.values,
    required this.labels,
    this.height = 46,
  }) : assert(values.length == labels.length);

  final List<int> values;
  final List<String> labels;
  final double height;

  @override
  Widget build(BuildContext context) {
    final maxValue = values.fold<int>(0, (m, v) => v > m ? v : m);
    final muted = Colors.white.withValues(alpha: 0.55);
    return SizedBox(
      height: height + 16,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: maxValue == 0
                        ? 3
                        : 3 + (height - 3) * values[i] / maxValue,
                    decoration: BoxDecoration(
                      color: i == values.length - 1
                          ? AppColors.accent
                          : Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    labels[i],
                    maxLines: 1,
                    style: AppFonts.label(
                      size: 10,
                      weight: i == values.length - 1
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: i == values.length - 1 ? AppColors.accent : muted,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The reading-spot photo behind a card, under a [scrim] that keeps the text
/// legible. Draws nothing when there is no photo.
class SharePhotoBackdrop extends StatelessWidget {
  const SharePhotoBackdrop({
    super.key,
    required this.photo,
    required this.scrim,
  });

  final ImageProvider? photo;
  final Decoration scrim;

  @override
  Widget build(BuildContext context) {
    final photo = this.photo;
    if (photo == null) return const SizedBox.shrink();
    return Stack(
      fit: StackFit.expand,
      children: [
        Image(image: photo, fit: BoxFit.cover),
        DecoratedBox(decoration: scrim),
      ],
    );
  }
}
