import 'package:flutter/material.dart';

import '../../../../core/utils/l10n_extension.dart';
import '../../../../core/utils/language_names.dart';
import '../../../search/domain/entities/book.dart';

class BookInfoSection extends StatelessWidget {
  const BookInfoSection({super.key, required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rows = <(String, String)>[
      if (book.publisher != null) (l10n.publisher, book.publisher!),
      if (book.publishedYear != null)
        (l10n.publishedYear, '${book.publishedYear}'),
      if (book.isbn != null) (l10n.isbn, book.isbn!),
      if (book.pageCount != null) (l10n.pages, '${book.pageCount}'),
      if (book.language != null) (l10n.language, languageName(book.language!)),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(
                        rows[i].$1,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        rows[i].$2,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
