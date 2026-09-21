import 'package:bookshelf/core/utils/isbn.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Isbn.parse', () {
    test('accepts a valid ISBN-13 (the barcode value)', () {
      expect(Isbn.parse('9780441172719'), '9780441172719');
      expect(Isbn.parse('9791032300176'), '9791032300176');
    });

    test('ignores hyphens and spaces', () {
      expect(Isbn.parse('978-0-441-17271-9'), '9780441172719');
      expect(Isbn.parse(' 978 0441 172719 '), '9780441172719');
    });

    test('rejects a wrong check digit', () {
      expect(Isbn.parse('9780441172718'), isNull);
    });

    test('rejects EAN-13 that are not books (no 978/979 prefix)', () {
      // Valid EAN-13 of a grocery item.
      expect(Isbn.parse('4006381333931'), isNull);
    });

    test('converts a valid ISBN-10 to ISBN-13', () {
      expect(Isbn.parse('0441172717'), '9780441172719');
      expect(Isbn.parse('0-441-17271-7'), '9780441172719');
    });

    test('handles the X check digit of ISBN-10', () {
      // 0-8044-2957-X is the textbook example of an ISBN-10 ending in X.
      expect(Isbn.parse('080442957X'), '9780804429573');
      expect(Isbn.parse('080442957x'), '9780804429573');
    });

    test('rejects an ISBN-10 with a wrong check digit', () {
      expect(Isbn.parse('0441172718'), isNull);
    });

    test('rejects garbage', () {
      expect(Isbn.parse(null), isNull);
      expect(Isbn.parse(''), isNull);
      expect(Isbn.parse('hello'), isNull);
      expect(Isbn.parse('12345'), isNull);
      expect(Isbn.parse('97804411727190'), isNull);
    });
  });
}
