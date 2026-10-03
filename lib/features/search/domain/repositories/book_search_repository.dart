import '../entities/author_info.dart';
import '../entities/book.dart';
import '../entities/book_edition.dart';
import '../entities/book_search_page.dart';
import '../entities/explore_genre.dart';
import '../entities/explore_section.dart';
import '../entities/reader_activity.dart';

abstract interface class BookSearchRepository {
  /// Free-text search (title, author or ISBN). [page] is 1-based. With
  /// [language] (`ita`, `eng`...) only books that exist in that language.
  /// Throws [Failure] on error.
  Future<BookSearchPage> search(String query, {int page = 1, String? language});

  /// The book with this ISBN-13, or null when Open Library does not know it.
  /// Tries the search index first, then Open Library's edition records.
  /// Throws [Failure] on error.
  Future<Book?> findByIsbn(String isbn);

  /// The work with this Open Library id (`OL45804W`), or null.
  /// Throws [Failure] on error.
  Future<Book?> findByWorkId(String workId);

  /// How many Open Library readers shelved [book] and whether it can be read
  /// online. Throws [Failure] on error.
  Future<ReaderActivity> getReaderActivity(Book book);

  /// Enriches [book] with work-level details (description, subjects, images,
  /// author ids, community rating).
  Future<Book> getBookDetails(Book book);

  /// Editions of the book's work, most complete first. Throws [Failure].
  Future<List<BookEdition>> getEditions(Book book);

  /// Author profile, or null when Open Library has no usable record.
  Future<AuthorInfo?> getAuthor(String authorKey);

  /// Other books by the same author, most popular first, without [exclude].
  Future<List<Book>> getBooksByAuthor(String authorKey, {String? exclude});

  /// Books sharing the subjects of [book], excluding [book] itself and its
  /// own authors' books.
  Future<List<Book>> getSimilarBooks(Book book);

  /// Books of an Explore [section], all with a cover. Served from a short
  /// cache unless [refresh] is set. Throws [Failure].
  Future<List<Book>> getExploreSection(
    ExploreSection section, {
    int limit,
    bool refresh,
  });

  /// Most popular books of [genre], all with a cover, in Open Library's
  /// reading-log order. Cached like the Explore shelves unless [refresh] is
  /// set. Throws [Failure].
  Future<List<Book>> getTopByGenre(
    ExploreGenre genre, {
    int limit,
    bool refresh,
  });
}
