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

  group('search doc extras', () {
    test('reads author ids and community rating', () {
      final book = OpenLibraryMapper.bookFromSearchDoc({
        'key': '/works/OL1W',
        'title': 'Dune',
        'author_key': ['OL79034A'],
        'ratings_average': 4.3018017,
        'ratings_count': 444,
      })!;
      expect(book.authorKeys, ['OL79034A']);
      expect(book.ratingAverage, closeTo(4.3, 0.01));
      expect(book.ratingsCount, 444);
      expect(book.hasCommunityRating, isTrue);
    });

    test('books nobody rated have no community rating', () {
      final book = OpenLibraryMapper.bookFromSearchDoc({
        'key': '/works/OL1W',
        'title': 'Dune',
      })!;
      expect(book.hasCommunityRating, isFalse);
    });
  });

  group('applyWork author ids', () {
    final work = {
      'authors': [
        {
          'author': {'key': '/authors/OL79034A'},
          'type': {'key': '/type/author_role'},
        },
      ],
    };

    test('reads them for books that had none (saved books)', () {
      final book = OpenLibraryMapper.applyWork(buildBook(), work);
      expect(book.authorKeys, ['OL79034A']);
    });

    test('keeps the search ids when present', () {
      final base = buildBook().copyWith(authorKeys: const ['OL1A']);
      expect(OpenLibraryMapper.applyWork(base, work).authorKeys, ['OL1A']);
    });
  });

  group('applyRatings', () {
    test('merges the summary', () {
      final book = OpenLibraryMapper.applyRatings(buildBook(), {
        'summary': {'average': 4.25, 'count': 12},
      });
      expect(book.ratingAverage, 4.25);
      expect(book.ratingsCount, 12);
    });

    test('ignores works without votes', () {
      final base = buildBook();
      final book = OpenLibraryMapper.applyRatings(base, {
        'summary': {'average': 0, 'count': 0},
      });
      expect(book, base);
    });
  });

  group('authorFromJson', () {
    test('maps profile, photo and life dates', () {
      final author = OpenLibraryMapper.authorFromJson(
        {
          'key': '/authors/OL79034A',
          'name': ' Frank Herbert ',
          'bio': {'type': '/type/text', 'value': 'American author.'},
          'birth_date': '8 October 1920',
          'death_date': '11 February 1986',
          'photos': [-1, 14852808],
        },
        workCount: 138,
      )!;
      expect(author.key, 'OL79034A');
      expect(author.name, 'Frank Herbert');
      expect(author.bio, 'American author.');
      expect(author.lifespan, '1920 – 1986');
      expect(author.workCount, 138);
      expect(
        author.photoUrl,
        'https://covers.openlibrary.org/a/id/14852808-M.jpg?default=false',
      );
    });

    test('drops the source footer Open Library appends to bios', () {
      final author = OpenLibraryMapper.authorFromJson({
        'key': '/authors/OL1A',
        'name': 'A',
        'bio': 'Real bio.\n\n----------\nSource: [wiki](http://x)',
      })!;
      expect(author.bio, 'Real bio.');
    });

    test('handles living authors and missing data', () {
      final author = OpenLibraryMapper.authorFromJson({
        'key': '/authors/OL1A',
        'name': 'A',
        'birth_date': '1965',
      })!;
      expect(author.lifespan, '* 1965');
      expect(author.photoUrl, isNull);
      expect(author.bio, isNull);
    });

    test('rejects records without a name', () {
      expect(
        OpenLibraryMapper.authorFromJson({'key': '/authors/OL1A'}),
        isNull,
      );
    });
  });
}
