import 'package:flutter/material.dart';

import '../../../../core/utils/l10n_extension.dart';

/// "Best sellers                                   View all ›"
class ExploreSectionHeader extends StatelessWidget {
  const ExploreSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onViewAll,
  });

  final String title;

  /// One line under the title, e.g. how a shelf is ranked.
  final String? subtitle;

  /// Null hides the "View all" link.
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onViewAll = this.onViewAll;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        if (onViewAll != null)
          InkWell(
            onTap: onViewAll,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(context.l10n.viewAll, style: theme.textTheme.bodySmall),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
