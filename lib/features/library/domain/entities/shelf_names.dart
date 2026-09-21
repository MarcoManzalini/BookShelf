/// Rules for the names of custom shelves (free-form tags on a book).
abstract final class ShelfNames {
  static const maxLength = 30;
  static const maxPerBook = 20;

  static final _spaces = RegExp(r'\s+');

  /// Trims and collapses whitespace; null when nothing usable is left.
  static String? normalize(String raw) {
    var name = raw.trim().replaceAll(_spaces, ' ');
    if (name.length > maxLength) name = name.substring(0, maxLength).trim();
    return name.isEmpty ? null : name;
  }

  /// Normalizes [names], drops duplicates (case-insensitively, keeping the
  /// first spelling) and caps the list at [maxPerBook].
  static List<String> clean(Iterable<String> names) {
    final seen = <String>{};
    final result = <String>[];
    for (final raw in names) {
      final name = normalize(raw);
      if (name == null || !seen.add(name.toLowerCase())) continue;
      result.add(name);
      if (result.length == maxPerBook) break;
    }
    return result;
  }

  static bool same(String a, String b) => a.toLowerCase() == b.toLowerCase();
}
