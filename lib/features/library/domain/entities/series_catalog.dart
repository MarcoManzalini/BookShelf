import 'book_series.dart';
import 'user_book.dart';

/// One saga as the library knows it: its books and what they say about it.
class Saga {
  const Saga({required this.name, required this.books});

  /// Spelling of the first book seen with this saga.
  final String name;

  /// Books of the saga, in volume order (books without a volume last).
  final List<UserBook> books;

  /// Length of the saga: the largest total any of its books gives.
  int? get total {
    int? best;
    for (final b in books) {
      final t = b.series!.total;
      if (t != null && (best == null || t > best)) best = t;
    }
    return best;
  }

  /// First volume no book of the library holds yet, after the last one.
  int get nextFreeVolume {
    var last = 0.0;
    for (final b in books) {
      final l = b.series!.lastIndex;
      if (l != null && l > last) last = l;
    }
    return last.floor() + 1;
  }

  /// The book holding volume [volume], if the library has it.
  UserBook? bookWith(num volume) =>
      books.where((b) => b.series!.covers(volume)).firstOrNull;
}

/// Every saga in the library, by name (case-insensitive).
abstract final class SeriesCatalog {
  static List<Saga> of(Iterable<UserBook> library) {
    final byName = <String, List<UserBook>>{};
    final spelling = <String, String>{};
    for (final book in library) {
      final series = book.series;
      if (series == null) continue;
      final key = series.name.trim().toLowerCase();
      spelling.putIfAbsent(key, () => series.name.trim());
      (byName[key] ??= []).add(book);
    }
    final sagas = [
      for (final entry in byName.entries)
        Saga(
          name: spelling[entry.key]!,
          books: entry.value
            ..sort(
              (a, b) => (a.series!.index ?? double.infinity)
                  .compareTo(b.series!.index ?? double.infinity),
            ),
        ),
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return sagas;
  }

  static Saga? find(Iterable<UserBook> library, String name) =>
      of(library).where((s) => BookSeries.sameName(s.name, name)).firstOrNull;
}
