import 'package:bookshelf/features/library/domain/entities/reading_status.dart';
import 'package:bookshelf/features/library_io/data/goodreads_csv_parser.dart';
import 'package:bookshelf/features/library_io/data/library_csv_exporter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures.dart';

const _header =
    'Book Id,Title,Author,Author l-f,Additional Authors,ISBN,ISBN13,'
    'My Rating,Average Rating,Publisher,Binding,Number of Pages,Year Published,'
    'Original Publication Year,Date Read,Date Added,Bookshelves,'
    'Bookshelves with positions,Exclusive Shelf,My Review,Spoiler,'
    'Private Notes,Read Count,Owned Copies';

String csvOf(List<String> lines) => [_header, ...lines].join('\n');

void main() {
  group('GoodreadsCsvParser', () {
    test('reads a typical Goodreads export row', () {
      final result = GoodreadsCsvParser.parse(
        csvOf([
          '1,"Dune (Dune Chronicles, #1)","Frank Herbert","Herbert, Frank",,'
              '="0441172717",="9780441172719",5,4.25,Ace,Paperback,604,1990,'
              '1965,2021/03/15,2020/12/01,"sci-fi, favorites",,read,'
              '"Loved it",,"Reread in 2025",1,0',
        ]),
      );

      expect(result.rows, hasLength(1));
      final row = result.rows.single;
      expect(row.title, 'Dune (Dune Chronicles, #1)');
      expect(row.author, 'Frank Herbert');
      expect(row.isbn13, '9780441172719', reason: 'Excel wrapper removed');
      expect(row.isbn10, '0441172717');
      expect(row.status, ReadingStatus.read);
      expect(row.rating, 5);
      expect(row.pages, 604);
      expect(row.finishedOn, DateTime(2021, 3, 15));
      expect(row.addedOn, DateTime(2020, 12, 1));
      expect(row.notes, 'Loved it\n\nReread in 2025');
      expect(row.shelves, ['Sci fi', 'favorites']);
    });

    test('maps the exclusive shelves to reading statuses', () {
      final result = GoodreadsCsvParser.parse(
        csvOf([
          ',A,,,,,,0,,,,,,,,,,,to-read,,,,,',
          ',B,,,,,,0,,,,,,,,,,,currently-reading,,,,,',
          ',C,,,,,,0,,,,,,,,,,,read,,,,,',
        ]),
      );
      expect(
        result.rows.map((r) => r.status),
        [ReadingStatus.wantToRead, ReadingStatus.reading, ReadingStatus.read],
      );
    });

    test('a finished date without a shelf means read', () {
      final result = GoodreadsCsvParser.parse(
        csvOf([',A,,,,,,0,,,,,,,2022/05/01,,,,,,,,,']),
      );
      expect(result.rows.single.status, ReadingStatus.read);
    });

    test('a zero rating is "not rated"', () {
      final result = GoodreadsCsvParser.parse(
        csvOf([',A,,,,,,0,,,,,,,,,,,to-read,,,,,']),
      );
      expect(result.rows.single.rating, isNull);
    });

    test('keeps multi-line quoted reviews intact', () {
      final result = GoodreadsCsvParser.parse(
        csvOf([
          ',A,,,,,,3,,,,,,,,,,,read,"line one\nline two",,,,',
        ]),
      );
      expect(result.rows.single.notes, 'line one\nline two');
    });

    test('built-in shelves are not custom shelves; slugs become words', () {
      final result = GoodreadsCsvParser.parse(
        csvOf([
          ',A,,,,,,0,,,,,,,,,"to-read, science-fiction, Gifts",,to-read,,,,,',
        ]),
      );
      expect(result.rows.single.shelves, ['Science fiction', 'Gifts']);
    });

    test('tolerates a byte order mark and blank lines', () {
      final result = GoodreadsCsvParser.parse(
        '﻿${csvOf([',A,,,,,,0,,,,,,,,,,,to-read,,,,,', ''])}\n\n',
      );
      expect(result.rows, hasLength(1));
      expect(result.skipped, 0);
    });

    test('counts lines without a title as skipped', () {
      final result = GoodreadsCsvParser.parse(
        csvOf([',,Someone,,,,,0,,,,,,,,,,,to-read,,,,,']),
      );
      expect(result.rows, isEmpty);
      expect(result.skipped, 1);
    });

    test('rejects a file that is not a book export', () {
      expect(
        () => GoodreadsCsvParser.parse('name,age\nAnna,30'),
        throwsA(isA<CsvFormatException>()),
      );
      expect(
        () => GoodreadsCsvParser.parse(''),
        throwsA(isA<CsvFormatException>()),
      );
    });

    test('ignores impossible dates', () {
      final result = GoodreadsCsvParser.parse(
        csvOf([',A,,,,,,0,,,,,,,2021/13/40,,,,to-read,,,,,']),
      );
      expect(result.rows.single.finishedOn, isNull);
    });
  });

  group('LibraryCsvExporter', () {
    final book = buildUserBook(
      book: buildBook(title: 'Dune, "the" book').copyWith(
        isbn: '9780441172719',
        publisher: 'Ace',
      ),
      status: ReadingStatus.read,
      rating: 5,
      finishedAt: DateTime(2026, 2, 3),
    ).copyWith(shelves: const ['Regali', 'Estate'], notes: () => 'Ottimo');

    test('writes Goodreads column names and quotes awkward values', () {
      final text = LibraryCsvExporter.build([book]);
      final lines = text.trim().split('\n');
      expect(lines.first, LibraryCsvExporter.header.join(','));
      expect(text, contains('"Dune, ""the"" book"'));
      expect(text, contains(',9780441172719,'));
      expect(text, isNot(contains('="')));
      expect(text, contains('2026/02/03'));
      expect(text, contains('"Regali, Estate"'));
      expect(text, isNot(contains('\r')));
    });

    test('what is exported can be imported again', () {
      final rows =
          GoodreadsCsvParser.parse(LibraryCsvExporter.build([book])).rows;
      final row = rows.single;

      expect(row.title, 'Dune, "the" book');
      expect(row.author, 'Frank Herbert');
      expect(row.isbn13, '9780441172719');
      expect(row.status, ReadingStatus.read);
      expect(row.rating, 5);
      expect(row.finishedOn, DateTime(2026, 2, 3));
      expect(row.notes, 'Ottimo');
      expect(row.shelves, ['Regali', 'Estate']);
      expect(row.pages, 400);
    });

    test('an empty library still yields a valid header-only file', () {
      final text = LibraryCsvExporter.build(const []);
      expect(text.trim(), LibraryCsvExporter.header.join(','));
    });
  });
}
