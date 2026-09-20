import '../../../../core/errors/error_mapper.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/book_search_page.dart';
import '../../domain/repositories/book_search_repository.dart';
import '../datasources/book_remote_data_source.dart';

class BookSearchRepositoryImpl implements BookSearchRepository {
  const BookSearchRepositoryImpl(this._remote);

  final BookRemoteDataSource _remote;

  @override
  Future<BookSearchPage> search(String query, {int page = 1}) async {
    try {
      return await _remote.search(query.trim(), page: page);
    } catch (e) {
      throw mapError(e);
    }
  }

  @override
  Future<Book> getBookDetails(Book book) async {
    try {
      return await _remote.fetchDetails(book);
    } catch (e) {
      throw mapError(e);
    }
  }
}
