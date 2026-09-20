import 'package:flutter/material.dart';

import '../../../../core/utils/l10n_extension.dart';
import '../../../../core/utils/language_names.dart';
import '../../../../core/widgets/catalog_card.dart';
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
    return CatalogCard(
      headerStart: book.authors.isEmpty ? null : book.authorsLabel,
      headerEnd: book.externalId,
      rows: rows,
    );
  }
}
