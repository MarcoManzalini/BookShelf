import 'book.dart';

/// Ranks books by rating quality *and* quantity.
///
/// A plain average lets one 5-star vote beat a 4.8 backed by fifty. The
/// Bayesian average pulls every book towards the pool's mean until it has
/// enough votes to stand on its own:
///
///   score = v / (v + m) * R + m / (v + m) * C
///
/// with R the book's average, v its votes, C a typical average for a rated
/// book and m the votes needed before the book's own average counts as much
/// as C. C is fixed rather than taken from the candidates: those are picked
/// among the best rated, so their own mean would be inflated.
class BookRanking {
  const BookRanking._();

  /// Votes at which a book's own average weighs as much as the pool mean.
  static const priorVotes = 30;

  /// Average a book is assumed to have before its own votes say otherwise.
  static const priorMean = 3.8;

  /// Bayesian score of one book, 0-5. 0 for an unrated book.
  static double score(Book book) {
    final votes = book.ratingsCount ?? 0;
    final average = book.ratingAverage;
    if (average == null || votes <= 0) return 0;
    return votes / (votes + priorVotes) * average +
        priorVotes / (votes + priorVotes) * priorMean;
  }

  /// [books] without unrated ones, best score first. Ties keep the incoming
  /// order, so a more popular book listed earlier stays ahead.
  static List<Book> rank(Iterable<Book> books) {
    final scored = [
      for (final b in books)
        if (b.hasCommunityRating) (book: b, score: score(b)),
    ];
    // List.sort is not stable: the index keeps ties in their original order.
    final indexed = scored.indexed.toList()
      ..sort((a, b) {
        final byScore = b.$2.score.compareTo(a.$2.score);
        return byScore != 0 ? byScore : a.$1.compareTo(b.$1);
      });
    return [for (final entry in indexed) entry.$2.book];
  }
}
