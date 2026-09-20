import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../utils/cover_url.dart';

/// Cover image with a local placeholder while loading, when missing, or when
/// Open Library answers 404 (`?default=false`).
class BookCover extends StatelessWidget {
  const BookCover({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.size = CoverSize.medium,
    this.borderRadius = 10,
    this.fit = BoxFit.cover,
  });

  final String? url;
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
      child: _content(context),
    );
    if (width == null && height == null) {
      return AspectRatio(aspectRatio: aspectRatio, child: image);
    }
    return SizedBox(width: width, height: height, child: image);
  }

  Widget _content(BuildContext context) {
    final source = url;
    if (source == null || source.isEmpty) return const _CoverPlaceholder();
    return CachedNetworkImage(
      imageUrl: resizeCoverUrl(source, size),
      httpHeaders: const {'User-Agent': AppConfig.userAgent},
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder: (_, __) => const _CoverPlaceholder(loading: true),
      errorWidget: (_, __, ___) => const _CoverPlaceholder(),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder({this.loading = false});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          loading ? Icons.menu_book_outlined : Icons.menu_book_rounded,
          color: scheme.onSurfaceVariant.withAlpha(loading ? 77 : 153),
          size: 28,
        ),
      ),
    );
  }
}
