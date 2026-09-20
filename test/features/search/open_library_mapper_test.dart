import 'package:bookshelf/features/search/data/mappers/open_library_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures.dart';

void main() {
  group('bookFromSearchDoc', () {
    test('maps a full document', () {
      final book = OpenLibraryMapper.bookFromSearchDoc({
        'key': '/works/OL893415W',
        'title': ' Dune ',
        'author_name': ['Frank Herbert'],
        'cover_i': 8231856,
        'first_publish_year': 1965,
        'isbn': ['0441172717', '9780441172719'],
        'number_of_pages_median': 604,
        'publisher': ['Ace Books', 'Chilton'],
        'subject': List.generate(30, (i) => 'subject $i'),
        'language': ['eng', 'ita'],
      })!;

      expect(book.externalId, 'OL893415W');
      expect(book.title, 'Dune');
      expect(book.authors, ['Frank Herbert']);
      expect(
        book.coverUrl,
        'https://covers.openlibrary.org/b/id/8231856-L.jpg?default=false',
      );
      expect(book.isbn, '9780441172719', reason: 'prefers ISBN-13');
      expect(book.pageCount, 604);
      expect(book.publisher, 'Ace Books');
      expect(book.publishedYear, 1965);
      expect(book.subjects, hasLength(10));
      expect(book.language, 'eng');
      expect(book.extraImages, isEmpty);
    });

    test('tolerates missing optional fields', () {
      final book = OpenLibraryMapper.bookFromSearchDoc({
        'key': '/works/OL1W',
        'title': 'Untitled',
      })!;
      expect(book.authors, isEmpty);
      expect(book.coverUrl, isNull);
      expect(book.isbn, isNull);
      expect(book.pageCount, isNull);
    });

    test('drops documents without key or title', () {
      expect(OpenLibraryMapper.bookFromSearchDoc({'title': 'x'}), isNull);
      expect(
        OpenLibraryMapper.bookFromSearchDoc({'key': '/works/OL1W'}),
        isNull,
      );
      expect(
        OpenLibraryMapper.bookFromSearchDoc(
          {'key': '/works/OL1W', 'title': ' '},
        ),
        isNull,
      );
    });
  });

  group('applyWork', () {
    test('reads a plain string description', () {
      final book = OpenLibraryMapper.applyWork(
        buildBook(),
        {'description': 'A desert planet.'},
      );
      expect(book.description, 'A desert planet.');
    });

    test('reads a typed description object', () {
      final book = OpenLibraryMapper.applyWork(buildBook(), {
        'description': {'type': '/type/text', 'value': 'Typed.'},
      });
      expect(book.description, 'Typed.');
    });

    test('keeps the existing description when the work has none', () {
      final book = OpenLibraryMapper.applyWork(
        buildBook(description: 'Existing'),
        {'title': 'Dune'},
      );
      expect(book.description, 'Existing');
    });

    test('exposes other covers as extra images, skipping invalid ids', () {
      final base = OpenLibraryMapper.bookFromSearchDoc({
        'key': '/works/OL1W',
        'title': 'Dune',
        'cover_i': 1,
      })!;
      final book = OpenLibraryMapper.applyWork(base, {
        'covers': [1, -1, 2, 3],
      });
      expect(book.extraImages, [
        OpenLibraryMapper.coverUrl(2),
        OpenLibraryMapper.coverUrl(3),
      ]);
      expect(book.images, hasLength(3));
    });

    test('falls back to a work cover when the search doc had none', () {
      final book = OpenLibraryMapper.applyWork(buildBook(), {
        'covers': [7],
      });
      expect(book.coverUrl, OpenLibraryMapper.coverUrl(7));
    });
  });
}
