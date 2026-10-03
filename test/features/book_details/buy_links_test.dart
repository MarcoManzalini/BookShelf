import 'package:bookshelf/features/book_details/domain/buy_links.dart';
import 'package:bookshelf/features/search/domain/entities/book.dart';
import 'package:flutter_test/flutter_test.dart';

Book _book({String? publisher, String? isbn}) => Book(
      externalId: 'OL1W',
      title: 'Se questo è un uomo',
      authors: const ['Primo Levi'],
      publisher: publisher,
      isbn: isbn,
    );

void main() {
  group('publisherLinkFor', () {
    test('recognizes the publisher in the Open Library spelling', () {
      final link = publisherLinkFor(_book(publisher: 'Giulio Einaudi Editore'));

      expect(link?.label, 'Einaudi');
      expect(
        link?.uri.toString(),
        'https://www.einaudi.it/?s=Se+questo+%C3%A8+un+uomo',
      );
    });

    test('ignores case, accents and punctuation', () {
      expect(publisherLinkFor(_book(publisher: 'ADELPHI'))?.label, 'Adelphi');
      expect(
        publisherLinkFor(_book(publisher: 'Edizioni e/o'))?.label,
        'Edizioni E/O',
      );
      expect(
        publisherLinkFor(_book(publisher: 'Neri Pozza Editore'))?.label,
        'Neri Pozza',
      );
    });

    test('opens the home page when the site search is not supported', () {
      final link = publisherLinkFor(_book(publisher: 'Adelphi'));
      expect(link?.uri.toString(), 'https://www.adelphi.it/');
    });

    test('matches whole words only', () {
      // "tea" is a publisher, "Teatro" is not.
      expect(publisherLinkFor(_book(publisher: 'Teatro Stabile')), isNull);
      expect(publisherLinkFor(_book(publisher: 'TEA'))?.label, 'TEA');
    });

    test('returns null for unknown or missing publishers', () {
      expect(publisherLinkFor(_book(publisher: 'Small Press')), isNull);
      expect(publisherLinkFor(_book()), isNull);
    });
  });

  group('storeLinksFor', () {
    test('searches the ISBN when there is one', () {
      final links = storeLinksFor(_book(isbn: '9788806219352'));

      expect(links.map((l) => l.label), ['Amazon', 'IBS', 'laFeltrinelli']);
      expect(
        links.first.uri.toString(),
        'https://www.amazon.it/s?k=9788806219352',
      );
      expect(links[1].uri.queryParameters['query'], '9788806219352');
    });

    test('falls back to title and first author', () {
      final links = storeLinksFor(_book());
      expect(
        links.first.uri.queryParameters['k'],
        'Se questo è un uomo Primo Levi',
      );
    });
  });

  test('buyLinksFor puts the publisher first', () {
    final links = buyLinksFor(_book(publisher: 'Einaudi'));

    expect(links.first, isA<PublisherLink>());
    expect(links, hasLength(4));
    expect(buyLinksFor(_book()), hasLength(3));
  });
}
