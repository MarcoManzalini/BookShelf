import '../entities/book.dart';
import '../entities/book_search_page.dart';

abstract interface class BookSearchRepository {
  /// Free-text search (title, author or ISBN). [page] is 1-based.
  /// Throws [Failure] on error.
  Future<BookSearchPage> search(String query, {int page = 1});

  /// Enriches [book] with work-level details (description, subjects, images).
  Future<Book> getBookDetails(Book book);
}
