import '../../../../core/errors/error_mapper.dart';
import '../../domain/entities/book_quote.dart';
import '../../domain/repositories/quote_repository.dart';
import '../datasources/quote_remote_data_source.dart';
import '../mappers/book_quote_mapper.dart';

class QuoteRepositoryImpl implements QuoteRepository {
  const QuoteRepositoryImpl(this._remote);

  final QuoteRemoteDataSource _remote;

  @override
  Future<List<BookQuote>> forBook(String userBookId) =>
      _guard(() => _remote.fetchForBook(userBookId));

  @override
  Future<BookQuote> add({
    required String userBookId,
    required String text,
    int? page,
  }) =>
      _guard(
        () => _remote.insert(
          BookQuoteMapper.toInsertJson(
            userBookId: userBookId,
            text: text,
            page: page,
          ),
        ),
      );

  @override
  Future<BookQuote> update(BookQuote quote) => _guard(
        () => _remote.update(quote.id, BookQuoteMapper.toUpdateJson(quote)),
      );

  @override
  Future<void> remove(String id) => _guard(() => _remote.delete(id));

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      throw mapError(e);
    }
  }
}
