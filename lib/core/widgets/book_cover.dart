import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/cover_url.dart';

/// Cover image with a soft spine highlight. When the cover is missing, still
/// loading or fails (Open Library answers 404 with `?default=false`), a poster
/// cover titled with [title] is drawn instead.
class BookCover extends StatelessWidget {
  const BookCover({
    super.key,
    required this.url,
    this.title,
    this.author,
    this.width,
    this.height,
    this.size = CoverSize.medium,
    this.borderRadius = 3,
    this.fit = BoxFit.cover,
  });

  final String? url;
  final String? title;
  final String? author;
  final double? width;
  final double? height;
  final CoverSize size;
  final double borderRadius;
  final BoxFit fit;

  static const aspectRatio = 2 / 3;

  @override
  Widget build(BuildContext context) {
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _content(),
          const _SpineShade(),
        ],
      ),
    );
    if (width == null && height == null) {
      return AspectRatio(aspectRatio: aspectRatio, child: image);
    }
    return SizedBox(width: width, height: height, child: image);
  }

  Widget _content() {
    final source = url;
    if (source == null || source.isEmpty) {
      return ClothCover(title: title, author: author);
    }
    return CachedNetworkImage(
      imageUrl: resizeCoverUrl(source, size),
      httpHeaders: const {'User-Agent': AppConfig.userAgent},
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder: (_, __) =>
          ClothCover(title: title, author: author, muted: true),
      errorWidget: (_, __, ___) => ClothCover(title: title, author: author),
    );
  }
}

/// Cover shown at its own proportions: the image is scaled to [height] and
/// never cropped or stretched, and the frame and shadow follow its real edges.
/// Books without an image get a cloth cover with the standard 2:3 shape.
class NaturalBookCover extends StatelessWidget {
  const NaturalBookCover({
    super.key,
    required this.url,
    required this.height,
    this.title,
    this.author,
    this.borderRadius = 4,
  });

  final String? url;
  final double height;
  final String? title;
  final String? author;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final source = url;
    if (source == null || source.isEmpty) return _cloth();
    return CachedNetworkImage(
      imageUrl: resizeCoverUrl(source, CoverSize.large),
      httpHeaders: const {'User-Agent': AppConfig.userAgent},
      fadeInDuration: const Duration(milliseconds: 150),
      imageBuilder: (context, image) => _frame(
        Stack(
          children: [
            Image(image: image, height: height, fit: BoxFit.contain),
            const Positioned.fill(child: _SpineShade()),
          ],
        ),
      ),
      placeholder: (_, __) => _cloth(muted: true),
      errorWidget: (_, __, ___) => _cloth(),
    );
  }

  Widget _cloth({bool muted = false}) => _frame(
        SizedBox(
          width: height * BookCover.aspectRatio,
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClothCover(title: title, author: author, muted: muted),
              const _SpineShade(),
            ],
          ),
        ),
      );

  Widget _frame(Widget child) {
    final radius = BorderRadius.circular(borderRadius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(46),
            blurRadius: 20,
            offset: const Offset(4, 10),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: radius, child: child),
    );
  }
}

/// Soft highlight and shadow along the spine edge.
class _SpineShade extends StatelessWidget {
  const _SpineShade();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: 0.09,
        heightFactor: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0x40000000), Color(0x14FFFFFF), Color(0x00000000)],
              stops: [0, 0.55, 1],
            ),
          ),
        ),
      ),
    );
  }
}

/// A flat, typographic poster cover for books without an image: colour picked
/// from the title so the same book always looks the same.
class ClothCover extends StatelessWidget {
  const ClothCover({super.key, this.title, this.author, this.muted = false});

  final String? title;
  final String? author;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final seed = (title ?? '')
        .codeUnits
        .fold<int>(0, (a, b) => (a * 31 + b) & 0x7fffffff);
    final paper = AppColors.posterCovers[seed % AppColors.posterCovers.length];
    final onPaper =
        ThemeData.estimateBrightnessForColor(paper) == Brightness.dark
            ? Colors.white
            : AppColors.ink;
    final ink = onPaper.withAlpha(muted ? 110 : 255);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth.isFinite ? constraints.maxWidth : 100.0;
        final inset = w * 0.1;
        final showText = !muted && title != null && w >= 44;
        // Size the title so its longest word fits on one line instead of
        // breaking mid-word (~0.62em per bold glyph).
        final longestWord = (title ?? '')
            .split(RegExp(r'\s+'))
            .fold<int>(1, (m, word) => word.length > m ? word.length : m);
        final fitSize = (w - inset * 2.4) / (0.62 * longestWord);
        final titleSize = (w * 0.14).clamp(9.0, 26.0).clamp(0.0, fitSize);
        return ColoredBox(
          color: paper,
          child: Padding(
            padding: EdgeInsets.fromLTRB(inset * 1.4, inset, inset, inset),
            child: showText
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          title!,
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.text(
                            size: titleSize.clamp(8.0, 26.0),
                            weight: FontWeight.w800,
                            height: 1.1,
                            letterSpacing: -0.4,
                            color: ink,
                          ),
                        ),
                      ),
                      if (author != null && author!.isNotEmpty && w >= 90) ...[
                        SizedBox(height: w * 0.05),
                        Text(
                          author!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.text(
                            size: (w * 0.075).clamp(7, 13),
                            weight: FontWeight.w500,
                            color: ink.withAlpha(200),
                          ),
                        ),
                      ],
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
