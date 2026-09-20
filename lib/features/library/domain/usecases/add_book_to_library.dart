import '../../../search/domain/entities/book.dart';
import '../../../search/domain/repositories/book_search_repository.dart';
import '../entities/reading_status.dart';
import '../entities/user_book.dart';
import '../repositories/library_repository.dart';

/// Saves a book, enriching it with work details (description) first on a
/// best-effort basis: a failed lookup never blocks the add.
class AddBookToLibrary {
  const AddBookToLibrary(this._search, this._library);

  final BookSearchRepository _search;
  final LibraryRepository _library;

  Future<UserBook> call(Book book, ReadingStatus status) async {
    var toSave = book;
    if (book.description == null) {
      try {
        toSave = await _search
            .getBookDetails(book)
            .timeout(const Duration(seconds: 5));
      } catch (_) {
        toSave = book;
      }
    }
    return _library.add(toSave, status);
  }
}
