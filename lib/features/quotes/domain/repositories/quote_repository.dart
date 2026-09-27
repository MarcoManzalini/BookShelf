import '../entities/book_quote.dart';

abstract interface class QuoteRepository {
  /// Quotes saved from one book, newest first. Throws [Failure] on error.
  Future<List<BookQuote>> forBook(String userBookId);

  Future<BookQuote> add({
    required String userBookId,
    required String text,
    int? page,
  });

  Future<BookQuote> update(BookQuote quote);

  Future<void> remove(String id);
}
