import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/l10n_extension.dart';
import '../../../../core/widgets/expandable_text.dart';
import '../../../search/domain/entities/author_info.dart';

/// Portrait, name, dates and biography of the book's author.
class AuthorSection extends StatelessWidget {
  const AuthorSection({super.key, required this.author});

  final AuthorInfo author;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final meta = [
      if (author.lifespan != null) author.lifespan!,
      if (author.workCount != null && author.workCount! > 0)
        l10n.authorWorkCount(author.workCount!),
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _Portrait(author: author),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(author.name, style: theme.textTheme.titleMedium),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(meta, style: theme.textTheme.bodySmall),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (author.bio != null) ...[
          const SizedBox(height: 12),
          ExpandableText(author.bio!),
        ],
      ],
    );
  }
}

class _Portrait extends StatelessWidget {
  const _Portrait({required this.author});

  final AuthorInfo author;

  static const _size = 64.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initials = author.name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    final fallback = ColoredBox(
      color: scheme.primaryContainer,
      child: Center(
        child: Text(
          initials,
          style: AppFonts.text(
            size: 22,
            weight: FontWeight.w700,
            color: scheme.onPrimaryContainer,
          ),
        ),
      ),
    );
    final photo = author.photoUrl;
    return SizedBox(
      width: _size,
      height: _size,
      child: ClipOval(
        child: photo == null
            ? fallback
            : CachedNetworkImage(
                imageUrl: photo,
                httpHeaders: const {'User-Agent': AppConfig.userAgent},
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 150),
                placeholder: (_, __) => fallback,
                errorWidget: (_, __, ___) => fallback,
              ),
      ),
    );
  }
}
