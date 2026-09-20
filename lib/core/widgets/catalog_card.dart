import 'package:flutter/material.dart';

import '../theme/app_typography.dart';

/// Library index card: typed header, red rule, ruled rows and a punch hole.
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
    final ruleColor = scheme.outlineVariant;
    final typed = AppFonts.label(size: 13.5, color: scheme.onSurface);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (headerStart != null || headerEnd != null) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    (headerStart ?? '').toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.label(
                      size: 12,
                      weight: FontWeight.w700,
                      letterSpacing: 1,
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
            const SizedBox(height: 8),
            Container(height: 1.5, color: scheme.secondary.withAlpha(170)),
          ],
          for (final (label, value) in rows) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 104,
                    child: Text(
                      label.toUpperCase(),
                      style: AppFonts.label(
                        size: 11.5,
                        letterSpacing: 1,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(child: Text(value, style: typed)),
                ],
              ),
            ),
            Container(height: 1, color: ruleColor),
          ],
          const SizedBox(height: 14),
          Center(
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.surface,
                border: Border.all(color: scheme.outlineVariant),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
