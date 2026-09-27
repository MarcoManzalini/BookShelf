import 'package:csv/csv.dart';

import '../../library/domain/entities/reading_status.dart';
import '../domain/import_row.dart';

class CsvParseResult {
  const CsvParseResult({required this.rows, this.skipped = 0});

  final List<ImportRow> rows;

  /// Lines that had no title and could not be imported.
  final int skipped;
}

/// Thrown when the file is not a book export we can read.
class CsvFormatException implements Exception {
  const CsvFormatException(this.message);

  final String message;

  @override
  String toString() => 'CsvFormatException: $message';
}

/// Reads the CSV that Goodreads exports (My Books → Import and export), and
/// the one this app exports, which uses the same columns.
abstract final class GoodreadsCsvParser {
  static const _builtInShelves = {'read', 'currently-reading', 'to-read'};

  /// Goodreads has no built-in "did not finish" or "paused" shelf: readers
  /// make their own, with one of these names. This app exports the first.
  static const _abandonedShelves = {
    'did-not-finish',
    'dnf',
    'abandoned',
    'abbandonati',
    'abbandonato',
  };
  static const _pausedShelves = {
    'paused',
    'on-hold',
    'in-pausa',
    'in-sospeso',
  };

  static CsvParseResult parse(String text) {
    // Excel likes to prepend a byte order mark.
    final clean = text.startsWith('﻿') ? text.substring(1) : text;
    final table = csv.decode(clean);
    if (table.isEmpty) {
      throw const CsvFormatException('The file is empty.');
    }

    final header = [
      for (final cell in table.first) cell.toString().trim().toLowerCase(),
    ];
    final title = header.indexOf('title');
    if (title < 0) {
      throw const CsvFormatException('No "Title" column: not a book export.');
    }
    int? col(String name) {
      final i = header.indexOf(name);
      return i < 0 ? null : i;
    }

    final author = col('author');
    final isbn = col('isbn');
    final isbn13 = col('isbn13');
    final rating = col('my rating');
    final pages = col('number of pages');
    final dateRead = col('date read');
    final dateAdded = col('date added');
    final shelves = col('bookshelves');
    final exclusive = col('exclusive shelf');
    final review = col('my review');
    final notes = col('private notes');
    final readCount = col('read count');

    String? cell(List<dynamic> row, int? index) {
      if (index == null || index >= row.length) return null;
      final value = _unwrapExcel(row[index].toString().trim());
      return value.isEmpty ? null : value;
    }

    final rows = <ImportRow>[];
    var skipped = 0;
    for (final row in table.skip(1)) {
      // A blank trailing line is not a skipped book.
      if (row.every((c) => c.toString().trim().isEmpty)) continue;
      final bookTitle = cell(row, title);
      if (bookTitle == null) {
        skipped++;
        continue;
      }
      final finished = _date(cell(row, dateRead));
      final ratingValue = int.tryParse(cell(row, rating) ?? '');
      final reviewText = cell(row, review);
      final notesText = cell(row, notes);
      final status = _status(cell(row, exclusive), finished);
      final times = int.tryParse(cell(row, readCount) ?? '') ?? 0;
      rows.add(
        ImportRow(
          title: bookTitle,
          author: cell(row, author),
          isbn13: cell(row, isbn13),
          isbn10: cell(row, isbn),
          status: status,
          rating: (ratingValue != null && ratingValue >= 1 && ratingValue <= 5)
              ? ratingValue
              : null,
          pages: _positive(cell(row, pages)),
          finishedOn: finished,
          addedOn: _date(cell(row, dateAdded)),
          notes: [reviewText, notesText].nonNulls.join('\n\n').isEmpty
              ? null
              : [reviewText, notesText].nonNulls.join('\n\n'),
          shelves: _shelves(cell(row, shelves)),
          // The read the status describes is not an earlier one.
          earlierReads: status == ReadingStatus.read
              ? (times - 1).clamp(0, _maxEarlierReads)
              : times.clamp(0, _maxEarlierReads),
        ),
      );
    }
    return CsvParseResult(rows: rows, skipped: skipped);
  }

  /// Goodreads writes ISBNs as `="0441172717"` so Excel keeps leading zeros.
  static String _unwrapExcel(String value) {
    if (value.startsWith('="') && value.endsWith('"')) {
      return value.substring(2, value.length - 1);
    }
    return value;
  }

  /// A sanity cap: a typo in a spreadsheet should not create 9999 reads.
  static const _maxEarlierReads = 50;

  static ReadingStatus _status(String? exclusiveShelf, DateTime? finished) {
    final shelf = exclusiveShelf?.toLowerCase();
    if (_abandonedShelves.contains(shelf)) return ReadingStatus.abandoned;
    if (_pausedShelves.contains(shelf)) return ReadingStatus.paused;
    switch (shelf) {
      case 'read':
        return ReadingStatus.read;
      case 'currently-reading':
        return ReadingStatus.reading;
      case 'to-read':
        return ReadingStatus.wantToRead;
    }
    return finished != null ? ReadingStatus.read : ReadingStatus.wantToRead;
  }

  static int? _positive(String? value) {
    final n = int.tryParse(value ?? '');
    return (n != null && n > 0) ? n : null;
  }

  /// `2021/03/15` (Goodreads), `2021-03-15` or ISO timestamps.
  static DateTime? _date(String? value) {
    if (value == null) return null;
    final match =
        RegExp(r'^(\d{4})[/-](\d{1,2})[/-](\d{1,2})').firstMatch(value);
    if (match == null) return null;
    final year = int.parse(match[1]!);
    final month = int.parse(match[2]!);
    final day = int.parse(match[3]!);
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    return DateTime(year, month, day);
  }

  static List<String> _shelves(String? value) {
    if (value == null) return const [];
    return [
      for (final raw in value.split(','))
        if (raw.trim().isNotEmpty && !_isStatusShelf(raw.trim()))
          _prettify(raw.trim()),
    ];
  }

  /// Shelves that stand for a reading status rather than a custom shelf.
  static bool _isStatusShelf(String name) {
    final key = name.toLowerCase();
    return _builtInShelves.contains(key) ||
        _abandonedShelves.contains(key) ||
        _pausedShelves.contains(key);
  }

  /// Goodreads shelf names are slugs (`science-fiction`); show them as words.
  static String _prettify(String name) {
    final isSlug =
        name == name.toLowerCase() && name.contains('-') && !name.contains(' ');
    if (!isSlug) return name;
    final words = name.replaceAll('-', ' ');
    return words[0].toUpperCase() + words.substring(1);
  }
}
