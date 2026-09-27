import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/l10n_extension.dart';
import '../../../../core/utils/minutes_text.dart';
import '../../../stats/domain/entities/reading_log.dart';

/// The reading sessions of a book, newest first, a page at a time so a long
/// history does not stretch the book page.
class ReadingSessionsList extends StatefulWidget {
  const ReadingSessionsList({
    super.key,
    required this.logs,
    this.pageSize = 5,
    this.onShare,
  });

  final List<ReadingLog> logs;
  final int pageSize;

  /// Null hides the share button of each session.
  final ValueChanged<ReadingLog>? onShare;

  @override
  State<ReadingSessionsList> createState() => _ReadingSessionsListState();
}

class _ReadingSessionsListState extends State<ReadingSessionsList> {
  int _page = 0;

  int get _pageCount => (widget.logs.length / widget.pageSize).ceil();

  @override
  void didUpdateWidget(ReadingSessionsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new session goes on top: show it. Fewer sessions: stay in range.
    final added = widget.logs.firstOrNull?.id != oldWidget.logs.firstOrNull?.id;
    if (added) {
      _page = 0;
    } else if (_page >= _pageCount) {
      _page = (_pageCount - 1).clamp(0, _pageCount);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final day = DateFormat.MMMd(locale);
    final total = widget.logs.length;
    final start = _page * widget.pageSize;
    final end = (start + widget.pageSize).clamp(0, total);
    final onShare = widget.onShare;

    return Column(
      children: [
        for (final log in widget.logs.sublist(start, end))
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
                      if (log.minutes != null)
                        MinutesText.format(l10n, log.minutes!),
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
                    onPressed: () => onShare(log),
                  ),
              ],
            ),
          ),
        if (_pageCount > 1)
          Row(
            children: [
              IconButton(
                tooltip: l10n.sessionsNewer,
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: _page > 0 ? () => setState(() => _page--) : null,
              ),
              Expanded(
                child: Text(
                  l10n.sessionsRange(start + 1, end, total),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.sessionsOlder,
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: _page < _pageCount - 1
                    ? () => setState(() => _page++)
                    : null,
              ),
            ],
          ),
      ],
    );
  }
}
