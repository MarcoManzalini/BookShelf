/// ISBN parsing and check-digit validation.
///
/// Book barcodes are EAN-13 codes starting with 978/979, i.e. the ISBN-13
/// itself. Older ISBN-10s (typed or in text) are converted to ISBN-13.
abstract final class Isbn {
  static final _separators = RegExp(r'[\s-]');
  static final _thirteen = RegExp(r'^\d{13}$');
  static final _ten = RegExp(r'^\d{9}[\dX]$');

  /// Returns [raw] as a valid ISBN-13, or null when it is not an ISBN.
  static String? parse(String? raw) {
    if (raw == null) return null;
    final s = raw.replaceAll(_separators, '').toUpperCase();
    if (_thirteen.hasMatch(s)) {
      final isBookland = s.startsWith('978') || s.startsWith('979');
      return isBookland && _checkDigit13(s.substring(0, 12)) == s[12]
          ? s
          : null;
    }
    if (_ten.hasMatch(s) && _isValid10(s)) {
      final body = '978${s.substring(0, 9)}';
      return '$body${_checkDigit13(body)}';
    }
    return null;
  }

  static String _checkDigit13(String first12) {
    var sum = 0;
    for (var i = 0; i < 12; i++) {
      sum += int.parse(first12[i]) * (i.isEven ? 1 : 3);
    }
    return '${(10 - sum % 10) % 10}';
  }

  static bool _isValid10(String s) {
    var sum = 0;
    for (var i = 0; i < 10; i++) {
      final digit = s[i] == 'X' ? 10 : int.parse(s[i]);
      sum += digit * (10 - i);
    }
    return sum % 11 == 0;
  }
}
