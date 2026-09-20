import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/cover_url.dart';

/// Cover image with a bound-book finish. When the cover is missing, still
/// loading or fails (Open Library answers 404 with `?default=false`), a cloth
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

/// A typographic cloth-bound cover: colour picked from the title so the same
/// book always looks the same.
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
    final cloth = AppColors.clothCovers[seed % AppColors.clothCovers.length];
    final foil = AppColors.brassLight.withAlpha(muted ? 120 : 235);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth.isFinite ? constraints.maxWidth : 100.0;
        final inset = w * 0.1;
        final showText = !muted && title != null && w >= 44;
        return ColoredBox(
          color: cloth,
          child: Padding(
            padding: EdgeInsets.fromLTRB(inset * 1.25, inset, inset, inset),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: foil.withAlpha(140), width: 1),
              ),
              child: Padding(
                padding: EdgeInsets.all(inset * 0.55),
                child: showText
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              title!,
                              textAlign: TextAlign.center,
                              maxLines: 5,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.serif(
                                size: (w * 0.115).clamp(8, 22),
                                weight: FontWeight.w700,
                                height: 1.18,
                                color: foil,
                              ),
                            ),
                          ),
                          if (author != null && w >= 90) ...[
                            SizedBox(height: w * 0.05),
                            Container(
                              width: w * 0.16,
                              height: 1,
                              color: foil.withAlpha(160),
                            ),
                            SizedBox(height: w * 0.05),
                            Text(
                              author!,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.serif(
                                size: (w * 0.075).clamp(7, 13),
                                style: FontStyle.italic,
                                color: foil.withAlpha(200),
                              ),
                            ),
                          ],
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
    );
  }
}
