import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/utils/l10n_extension.dart';
import '../../../../core/utils/open_link.dart';
import '../../../search/domain/entities/reader_activity.dart';

/// The work's page on Open Library, where it can be read or borrowed.
Uri openLibraryWorkUri(String workId) =>
    Uri.parse('${AppConfig.openLibraryBaseUrl}/works/$workId');

/// "1,211 want to read · 97 reading · 192 read" from Open Library's reading
/// logs. Hidden when nobody shelved the book.
class ReaderCountsLine extends StatelessWidget {
  const ReaderCountsLine({super.key, required this.activity});

  final ReaderActivity activity;

  @override
  Widget build(BuildContext context) {
    if (!activity.hasReaders) return const SizedBox.shrink();
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final parts = [
      if (activity.wantToRead > 0) l10n.readersWantToRead(activity.wantToRead),
      if (activity.reading > 0) l10n.readersReading(activity.reading),
      if (activity.read > 0) l10n.readersRead(activity.read),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 18,
            color: theme.colorScheme.secondary,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              parts.join(' · '),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens the work on Open Library when it is free to read there (public
/// domain scans). Borrowing is offered, smaller, under "Where to buy".
class ReadOnlineButton extends StatelessWidget {
  const ReadOnlineButton({
    super.key,
    required this.workId,
    required this.access,
  });

  final String workId;
  final EbookAccess access;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (access != EbookAccess.public) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: FilledButton.tonalIcon(
        onPressed: () => openExternalLink(context, openLibraryWorkUri(workId)),
        icon: const Icon(Icons.menu_book_rounded, size: 20),
        label: Text(l10n.readOnlineFree),
      ),
    );
  }
}
