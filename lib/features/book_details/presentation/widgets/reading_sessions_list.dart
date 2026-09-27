import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/l10n_extension.dart';
import '../../../stats/domain/entities/reading_log.dart';

/// The latest reading sessions of a book: day, pages and minutes.
class ReadingSessionsList extends StatelessWidget {
  const ReadingSessionsList({
    super.key,
    required this.logs,
    this.limit = 5,
    this.onShare,
  });

  final List<ReadingLog> logs;
  final int limit;

  /// Null hides the share button of each session.
  final ValueChanged<ReadingLog>? onShare;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final day = DateFormat.MMMd(locale);
    return Column(
      children: [
        for (final log in logs.take(limit))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  child: Text(
                    day.format(log.loggedOn),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                Expanded(
                  child: Text(
                    [
                      if (log.pages > 0) l10n.pagesCount(log.pages),
                      if (log.minutes != null) l10n.minutesShort(log.minutes!),
                    ].join(' · '),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                if (onShare != null && log.hasActivity)
                  IconButton(
                    tooltip: l10n.sessionShare,
                    visualDensity: VisualDensity.compact,
                    iconSize: 18,
                    icon: const Icon(Icons.ios_share_rounded),
                    onPressed: () => onShare!(log),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
