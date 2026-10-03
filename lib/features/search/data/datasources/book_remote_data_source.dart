import 'package:dio/dio.dart';

import '../../domain/entities/author_info.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/book_edition.dart';
import '../../domain/entities/book_search_page.dart';
import '../../domain/entities/explore_genre.dart';
import '../../domain/entities/explore_section.dart';
import '../../domain/entities/reader_activity.dart';
import '../mappers/open_library_mapper.dart';

abstract interface class BookRemoteDataSource {
  Future<BookSearchPage> search(String query, {required int page});
  Future<Book> fetchDetails(Book base);

  /// The edition with this ISBN, read straight from Open Library's records
  /// (`/isbn/{isbn}.json`) rather than from the search index, which lags
  /// behind new editions. Open Library may also import a missing ISBN from
  /// its partners on this call. Null when it has no such edition.
  Future<Book?> fetchByIsbn(String isbn);

  /// Reading-log counts and online availability of a work.
  Future<ReaderActivity> fetchReaderActivity(String workId);
  Future<List<BookEdition>> fetchEditions(String workId);
  Future<AuthorInfo?> fetchAuthor(String authorKey);
  Future<List<Book>> fetchBooksByAuthor(String authorKey, {int limit});
  Future<List<Book>> fetchBooksBySubjects(List<String> subjects, {int limit});
  Future<List<Book>> fetchExplore(ExploreSection section, {required int limit});

  /// The most popular books of [genre], in Open Library's own `readinglog`
  /// order (want to read + reading + read), with a cover and a few votes.
  Future<List<Book>> fetchTopByGenre(ExploreGenre genre, {required int limit});
}

class OpenLibraryDataSource implements BookRemoteDataSource {
  OpenLibraryDataSource(this._dio);

  final Dio _dio;

  static const pageSize = 20;
  static const _fields = 'key,title,author_name,author_key,cover_i,'
      'first_publish_year,isbn,number_of_pages_median,publisher,subject,'
      'language,edition_count,ratings_average,ratings_count';

  /// Lighter projection for carousels: no need for the heavy `isbn`/`subject`
  /// arrays Open Library returns for every edition.
  static const _listFields = 'key,title,author_name,author_key,cover_i,'
      'first_publish_year,ratings_average,ratings_count';

  /// A new search supersedes the previous one: its request is cancelled so it
  /// stops competing for bandwidth and Open Library's rate limit.
  CancelToken? _searchToken;

  final _works = <String, Map<String, dynamic>>{};

  @override
  Future<BookSearchPage> search(String query, {required int page}) async {
    if (page <= 1) {
      _searchToken?.cancel();
      _searchToken = CancelToken();
    }
    final data = await _getJson(
      '/search.json',
      queryParameters: {
        'q': query,
        'fields': _fields,
        'limit': pageSize,
        'page': page,
      },
      cancelToken: _searchToken,
    );
    final docs = _docs(data);
    final start = (data['start'] as num?)?.toInt() ?? 0;
    final total = (data['numFound'] as num?)?.toInt() ?? 0;
    return BookSearchPage(
      books: docs.map(OpenLibraryMapper.bookFromSearchDoc).nonNulls.toList(),
      page: page,
      hasMore: start + docs.length < total,
    );
  }

  @override
  Future<Book> fetchDetails(Book base) async {
    final ratings = _getJson('/works/${base.externalId}/ratings.json')
        .then<Map<String, dynamic>?>((json) => json)
        .catchError((Object _) => null);
    final work = await _work(base.externalId);
    var book = OpenLibraryMapper.applyWork(base, work);
    final ratingsJson = await ratings;
    if (ratingsJson != null) {
      book = OpenLibraryMapper.applyRatings(book, ratingsJson);
    }
    return book;
  }

  @override
  Future<Book?> fetchByIsbn(String isbn) async {
    final Map<String, dynamic> edition;
    try {
      // Redirects to the edition, `/books/OL...M.json`.
      edition = await _getJson('/isbn/$isbn.json');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
    final workId = OpenLibraryMapper.workIdOfEdition(edition);
    if (workId == null) return null;
    var authorKeys = OpenLibraryMapper.editionAuthorKeys(edition);
    if (authorKeys.isEmpty) {
      try {
        authorKeys = OpenLibraryMapper.workAuthorKeys(await _work(workId));
      } on DioException {
        // A book without author is still a book.
      }
    }
    // Editions only reference their authors: the names need one lookup each.
    final keys = authorKeys.take(_maxEditionAuthors).toList();
    final names = await Future.wait([
      for (final key in keys)
        _getJson('/authors/$key.json')
            .then<String?>((json) => (json['name'] as String?)?.trim())
            .catchError((Object _) => null),
    ]);
    return OpenLibraryMapper.bookFromEdition(
      edition,
      authors: names.nonNulls.where((n) => n.isNotEmpty).toList(),
      authorKeys: keys,
    );
  }

  static const _maxEditionAuthors = 3;

  @override
  Future<ReaderActivity> fetchReaderActivity(String workId) async {
    final data = await _getJson(
      '/search.json',
      queryParameters: {
        'q': 'key:/works/$workId',
        'fields': 'want_to_read_count,currently_reading_count,'
            'already_read_count,ebook_access',
        'limit': 1,
      },
    );
    final doc = _docs(data).firstOrNull;
    return doc == null
        ? const ReaderActivity()
        : OpenLibraryMapper.readerActivityFromDoc(doc);
  }

  @override
  Future<List<BookEdition>> fetchEditions(String workId) async {
    final data = await _getJson(
      '/works/$workId/editions.json',
      queryParameters: {'limit': 100},
    );
    return (data['entries'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(OpenLibraryMapper.editionFromJson)
        .nonNulls
        .toList();
  }

  @override
  Future<AuthorInfo?> fetchAuthor(String authorKey) async {
    final workCount = _getJson(
      '/authors/$authorKey/works.json',
      queryParameters: {'limit': 1},
    )
        .then<int?>((json) => (json['size'] as num?)?.toInt())
        .catchError((Object _) => null);
    final author = await _getJson('/authors/$authorKey.json');
    return OpenLibraryMapper.authorFromJson(
      author,
      workCount: await workCount,
    );
  }

  @override
  Future<List<Book>> fetchBooksByAuthor(
    String authorKey, {
    int limit = 12,
  }) {
    return _searchList(
      'author_key:$authorKey',
      sort: 'editions',
      limit: limit,
    );
  }

  @override
  Future<List<Book>> fetchBooksBySubjects(
    List<String> subjects, {
    int limit = 12,
  }) {
    if (subjects.isEmpty) return Future.value(const []);
    final query =
        subjects.map((s) => 'subject:"${s.replaceAll('"', '')}"').join(' AND ');
    return _searchList(query, sort: 'readinglog', limit: limit);
  }

  @override
  Future<List<Book>> fetchExplore(
    ExploreSection section, {
    required int limit,
  }) {
    // Only books with a cover: these shelves are all about the artwork.
    const withCover = 'cover_i:[1 TO *]';
    switch (section) {
      case ExploreSection.bestSellers:
        return _trending(limit);
      case ExploreSection.newArrivals:
        final year = DateTime.now().year;
        return _searchList(
          'first_publish_year:[${year - 1} TO $year] AND '
          'ratings_count:[3 TO *] AND $withCover',
          sort: 'readinglog',
          limit: limit,
        );
      case ExploreSection.popular:
        // Candidates only: the repository ranks them on votes and quantity.
        return _ratedCandidates(
          'ratings_count:[$_popularMinVotes TO *] AND $withCover',
        );
    }
  }

  @override
  Future<List<Book>> fetchTopByGenre(
    ExploreGenre genre, {
    required int limit,
  }) {
    return _searchList(
      'subject:"${genre.subject}" AND '
      'ratings_count:[$_genreMinVotes TO *] AND cover_i:[1 TO *]',
      sort: 'readinglog',
      limit: limit,
    );
  }

  /// Most read books have the votes, top averaged ones the quality: the
  /// Bayesian ranking needs both to pick the real best.
  Future<List<Book>> _ratedCandidates(String query) async {
    final pools = await Future.wait([
      _searchList(query, sort: 'readinglog', limit: _candidatePool),
      _searchList(query, sort: 'rating', limit: _candidatePool),
    ]);
    final seen = <String>{};
    return [
      for (final book in pools.expand((p) => p))
        if (seen.add(book.externalId)) book,
    ];
  }

  static const _candidatePool = 60;
  static const _genreMinVotes = 10;
  static const _popularMinVotes = 50;

  Future<List<Book>> _trending(int limit) async {
    final data = await _getJson(
      '/trending/weekly.json',
      queryParameters: {'limit': limit, 'fields': _listFields},
    );
    return (data['works'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(OpenLibraryMapper.bookFromSearchDoc)
        .nonNulls
        .toList();
  }

  Future<List<Book>> _searchList(
    String query, {
    required String sort,
    required int limit,
  }) async {
    final data = await _getJson(
      '/search.json',
      queryParameters: {
        'q': query,
        'sort': sort,
        'fields': _listFields,
        'limit': limit,
      },
    );
    return _docs(data)
        .map(OpenLibraryMapper.bookFromSearchDoc)
        .nonNulls
        .toList();
  }

  /// Work documents are immutable enough for a session: cached so the details
  /// page and the extras it triggers never download the same work twice.
  Future<Map<String, dynamic>> _work(String id) async {
    final cached = _works[id];
    if (cached != null) return cached;
    return _works[id] = await _getJson('/works/$id.json');
  }

  Future<Map<String, dynamic>> _getJson(
    String path, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      path,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    );
    return response.data ?? const {};
  }

  List<Map<String, dynamic>> _docs(Map<String, dynamic> data) =>
      (data['docs'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList();
}
