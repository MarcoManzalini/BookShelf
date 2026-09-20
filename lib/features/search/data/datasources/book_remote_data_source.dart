import 'package:dio/dio.dart';

import '../../domain/entities/book.dart';
import '../../domain/entities/book_search_page.dart';
import '../mappers/open_library_mapper.dart';

abstract interface class BookRemoteDataSource {
  Future<BookSearchPage> search(String query, {required int page});
  Future<Book> fetchDetails(Book base);
}

class OpenLibraryDataSource implements BookRemoteDataSource {
  OpenLibraryDataSource(this._dio);

  final Dio _dio;

  static const pageSize = 20;
  static const _fields = 'key,title,author_name,cover_i,first_publish_year,'
      'isbn,number_of_pages_median,publisher,subject,language,edition_count';

  @override
  Future<BookSearchPage> search(String query, {required int page}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/search.json',
      queryParameters: {
        'q': query,
        'fields': _fields,
        'limit': pageSize,
        'page': page,
      },
    );
    final data = response.data ?? const {};
    final docs = (data['docs'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>();
    final books =
        docs.map(OpenLibraryMapper.bookFromSearchDoc).nonNulls.toList();
    final start = (data['start'] as num?)?.toInt() ?? 0;
    final total = (data['numFound'] as num?)?.toInt() ?? 0;
    return BookSearchPage(
      books: books,
      page: page,
      hasMore: start + docs.length < total,
    );
  }

  @override
  Future<Book> fetchDetails(Book base) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/works/${base.externalId}.json',
    );
    final work = response.data;
    if (work == null) return base;
    return OpenLibraryMapper.applyWork(base, work);
  }
}
