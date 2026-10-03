import 'package:flutter/material.dart';

import '../../../../core/utils/l10n_extension.dart';
import '../../../../core/utils/open_link.dart';
import '../../../search/domain/entities/book.dart';
import '../../domain/buy_links.dart';
import 'reader_activity_view.dart';

/// "Where to buy": the publisher's site in evidence when the publisher is
/// known, then the general bookstores and, in small, Open Library's digital
/// loan when the book can be borrowed. Links open in the browser.
class BuyLinksSection extends StatelessWidget {
  const BuyLinksSection({
    super.key,
    required this.book,
    this.borrowable = false,
  });

  final Book book;

  /// Open Library lends a digital copy (needs an Open Library account).
  final bool borrowable;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final links = buyLinksFor(book);
    final publisher = links.whereType<PublisherLink>().firstOrNull;
    final stores = links.where((l) => l is! PublisherLink);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (publisher != null) ...[
          FilledButton.tonalIcon(
            onPressed: () => openExternalLink(context, publisher.uri),
            icon: const Icon(Icons.storefront_outlined, size: 20),
            label: Text('${l10n.buyFromPublisher} · ${publisher.label}'),
          ),
          const SizedBox(height: 12),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final store in stores)
              ActionChip(
                avatar: const Icon(Icons.open_in_new_rounded, size: 16),
                label: Text(store.label),
                onPressed: () => openExternalLink(context, store.uri),
              ),
          ],
        ),
        if (borrowable)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                visualDensity: VisualDensity.compact,
                textStyle: Theme.of(context).textTheme.bodySmall,
              ),
              onPressed: () => openExternalLink(
                context,
                openLibraryWorkUri(book.externalId),
              ),
              icon: const Icon(Icons.local_library_outlined, size: 16),
              label: Text(l10n.readOnlineBorrow),
            ),
          ),
      ],
    );
  }
}
