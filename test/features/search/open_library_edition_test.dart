import 'package:bookshelf/features/search/data/mappers/open_library_mapper.dart';
import 'package:bookshelf/features/search/domain/entities/reader_activity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('bookFromEdition', () {
    final edition = {
      'key': '/books/OL35605422M',
      'title': 'Se questo è un uomo',
      'works': [
        {'key': '/works/OL1013794W'},
      ],
      'authors': [
        {'key': '/authors/OL74802A'},
      ],
      'publishers': ['Einaudi'],
      'publish_date': '2014',
      'number_of_pages': 224,
      'isbn_13': ['9788806219352'],
      'languages': [
        {'key': '/languages/ita'},
      ],
      'covers': [12345],
    };

    test('builds the work with the edition details', () {
      final book = OpenLibraryMapper.bookFromEdition(
        edition,
        authors: ['Primo Levi'],
        authorKeys: ['OL74802A'],
      )!;

      expect(book.externalId, 'OL1013794W');
      expect(book.editionKey, 'OL35605422M');
      expect(book.title, 'Se questo è un uomo');
      expect(book.authors, ['Primo Levi']);
      expect(book.authorKeys, ['OL74802A']);
      expect(book.publisher, 'Einaudi');
      expect(book.publishedYear, 2014);
      expect(book.pageCount, 224);
      expect(book.isbn, '9788806219352');
      expect(book.language, 'ita');
      expect(book.coverUrl, contains('12345'));
    });

    test('needs a work and a title', () {
      expect(
        OpenLibraryMapper.bookFromEdition({...edition, 'works': <Object>[]}),
        isNull,
      );
      expect(
        OpenLibraryMapper.bookFromEdition({...edition, 'title': ' '}),
        isNull,
      );
    });

    test('reads author ids of the edition', () {
      expect(OpenLibraryMapper.editionAuthorKeys(edition), ['OL74802A']);
    });
  });

  group('readerActivityFromDoc', () {
    test('reads the counts and the online access', () {
      final activity = OpenLibraryMapper.readerActivityFromDoc({
        'want_to_read_count': 1211,
        'currently_reading_count': 97,
        'already_read_count': 192,
        'ebook_access': 'borrowable',
      });

      expect(
        activity,
        const ReaderActivity(
          wantToRead: 1211,
          reading: 97,
          read: 192,
          ebookAccess: EbookAccess.borrowable,
        ),
      );
      expect(activity.hasReaders, isTrue);
    });

    test('treats other access values and missing counts as none', () {
      for (final access in ['printdisabled', 'no_ebook', null]) {
        final activity =
            OpenLibraryMapper.readerActivityFromDoc({'ebook_access': access});
        expect(activity.ebookAccess, EbookAccess.none);
        expect(activity.hasReaders, isFalse);
      }
      expect(
        OpenLibraryMapper.readerActivityFromDoc({'ebook_access': 'public'})
            .ebookAccess,
        EbookAccess.public,
      );
    });
  });
}
