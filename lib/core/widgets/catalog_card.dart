import 'package:flutter/material.dart';

import '../theme/app_typography.dart';

/// Key/value sheet: a soft white card with a heading and hairline-separated
/// rows.
class CatalogCard extends StatelessWidget {
  const CatalogCard({
    super.key,
    required this.rows,
    this.headerStart,
    this.headerEnd,
  });

  final List<(String, String)> rows;
  final String? headerStart;
  final String? headerEnd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(
              scheme.brightness == Brightness.dark ? 90 : 24,
            ),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (headerStart != null || headerEnd != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      headerStart ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.text(
                        size: 14,
                        weight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  if (headerEnd != null) ...[
                    const SizedBox(width: 12),
                    Text(
                      headerEnd!,
                      style: AppFonts.label(
                        size: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0 || headerStart != null || headerEnd != null)
              Divider(height: 1, color: scheme.outlineVariant),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 104,
                    child: Text(
                      rows[i].$1,
                      style: AppFonts.label(
                        size: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      rows[i].$2,
                      style: AppFonts.text(
                        size: 13.5,
                        weight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
