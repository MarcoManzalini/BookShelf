import 'package:csv/csv.dart';
import 'package:intl/intl.dart';

import '../../library/domain/entities/reading_status.dart';
import '../../library/domain/entities/user_book.dart';

/// Writes the library as a CSV with Goodreads' column names, so it opens in a
/// spreadsheet and can be imported into other reading apps.
abstract final class LibraryCsvExporter {
  static const header = [
    'Title',
    'Author',
    'ISBN',
    'ISBN13',
    'My Rating',
    'Publisher',
    'Number of Pages',
    'Year Published',
    'Date Read',
    'Date Added',
    'Bookshelves',
    'Exclusive Shelf',
    'My Review',
  ];

  static final _day = DateFormat('yyyy/MM/dd');

  static String build(List<UserBook> books) {
    final rows = <List<Object?>>[
      header,
      for (final b in books)
        [
          b.book.title,
          b.book.authorsLabel,
          _isbn10(b.book.isbn) ?? '',
          _isbn13(b.book.isbn) ?? '',
          b.rating ?? 0,
          b.book.publisher ?? '',
          b.book.pageCount ?? '',
          b.book.publishedYear ?? '',
          b.finishedAt == null ? '' : _day.format(b.finishedAt!),
          _day.format(b.createdAt),
          b.shelves.join(', '),
          _exclusiveShelf(b.status),
          b.notes ?? '',
        ],
    ];
    // \n: spreadsheets and the importer both accept it, and it avoids the
    // doubled carriage returns some platforms write with \r\n.
    return Csv(lineDelimiter: '\n').encode(rows);
  }

  static String _exclusiveShelf(ReadingStatus status) => switch (status) {
        ReadingStatus.read => 'read',
        ReadingStatus.reading => 'currently-reading',
        ReadingStatus.wantToRead => 'to-read',
      };

  static String? _isbn13(String? isbn) =>
      isbn != null && isbn.length == 13 ? isbn : null;

  static String? _isbn10(String? isbn) =>
      isbn != null && isbn.length == 10 ? isbn : null;
}
