import 'package:flutter/foundation.dart';

import '../../l10n/gen/app_localizations.dart';
import '../library/domain/entities/reading_status.dart';
import '../library/domain/entities/user_book.dart';
import '../library/presentation/widgets/book_extras_ui.dart';

/// One book line of the library widget.
@immutable
class LibraryWidgetRow {
  const LibraryWidgetRow({
    required this.id,
    required this.title,
    required this.subtitle,
    this.progress = -1,
  });

  final String id;
  final String title;
  final String subtitle;

  /// 0..100, or -1 to hide the bar.
  final int progress;
}

/// What the library widget shows: how many books are on each shelf, the
/// books being read, the next ones waiting and the custom shelves.
@immutable
class LibraryWidgetData {
  const LibraryWidgetData({
    required this.readingCount,
    required this.wantCount,
    required this.readCount,
    required this.reading,
    required this.wantToRead,
    required this.shelves,
    required this.labels,
  });

  /// Rows the native layout has room for, per section.
  static const maxRows = 3;

  /// Custom shelves named in the shelves line.
  static const maxShelves = 4;

  final int readingCount;
  final int wantCount;
  final int readCount;
  final List<LibraryWidgetRow> reading;
  final List<LibraryWidgetRow> wantToRead;

  /// "Favourites 12 · Fantasy 8", or empty without custom shelves.
  final String shelves;
  final Map<String, String> labels;

  static LibraryWidgetData compute({
    required List<UserBook> books,
    required AppLocalizations l10n,
  }) {
    List<UserBook> withStatus(ReadingStatus status) => [
          for (final b in books)
            if (b.status == status) b,
        ];
    final reading = withStatus(ReadingStatus.reading);
    // The most recently added first: the ones the reader has in mind.
    final want = withStatus(ReadingStatus.wantToRead)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final shelfCounts = <String, int>{};
    final spelling = <String, String>{};
    for (final b in books) {
      for (final shelf in b.shelves) {
        final name = spelling.putIfAbsent(shelf.toLowerCase(), () => shelf);
        shelfCounts[name] = (shelfCounts[name] ?? 0) + 1;
      }
    }
    final topShelves = shelfCounts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });

    return LibraryWidgetData(
      readingCount: reading.length,
      wantCount: want.length,
      readCount: withStatus(ReadingStatus.read).length,
      reading: [
        for (final b in reading.take(maxRows))
          LibraryWidgetRow(
            id: b.id,
            title: b.book.title,
            subtitle: b.progressLabel(l10n),
            progress: b.progress == null ? -1 : (b.progress! * 100).round(),
          ),
      ],
      wantToRead: [
        for (final b in want.take(maxRows))
          LibraryWidgetRow(
            id: b.id,
            title: b.book.title,
            subtitle: b.book.authors.firstOrNull ?? '',
          ),
      ],
      shelves: [
        for (final e in topShelves.take(maxShelves)) '${e.key} ${e.value}',
      ].join(' · '),
      labels: {
        'lib_label_reading': l10n.statusReading,
        'lib_label_want': l10n.statusWantToRead,
        'lib_label_read': l10n.widgetShelfRead,
        'lib_label_shelves': l10n.widgetShelves,
        'lib_label_empty': l10n.widgetShelfEmpty,
      },
    );
  }

  Map<String, Object> toMap() {
    final map = <String, Object>{
      'lib_reading_count': readingCount,
      'lib_want_count': wantCount,
      'lib_read_count': readCount,
      'lib_shelves': shelves,
      ...labels,
    };
    void rows(String prefix, List<LibraryWidgetRow> list) {
      for (var i = 0; i < maxRows; i++) {
        final row = i < list.length ? list[i] : null;
        map['${prefix}_${i}_id'] = row?.id ?? '';
        map['${prefix}_${i}_title'] = row?.title ?? '';
        map['${prefix}_${i}_sub'] = row?.subtitle ?? '';
        map['${prefix}_${i}_progress'] = row?.progress ?? -1;
      }
    }

    rows('lib_r', reading);
    rows('lib_w', wantToRead);
    return map;
  }
}
