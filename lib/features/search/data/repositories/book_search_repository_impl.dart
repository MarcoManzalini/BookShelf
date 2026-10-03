import '../../../../core/errors/error_mapper.dart';
import '../../domain/entities/author_info.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/book_edition.dart';
import '../../domain/entities/book_search_page.dart';
import '../../domain/entities/book_ranking.dart';
import '../../domain/entities/explore_genre.dart';
import '../../domain/entities/explore_section.dart';
import '../../domain/entities/reader_activity.dart';
import '../../domain/repositories/book_search_repository.dart';
import '../datasources/book_remote_data_source.dart';

class BookSearchRepositoryImpl implements BookSearchRepository {
  BookSearchRepositoryImpl(
    this._remote, {
    DateTime Function() now = DateTime.now,
    this.cacheSize = 40,
    this.cacheTtl = const Duration(minutes: 10),
  }) : _now = now;

  final BookRemoteDataSource _remote;
  final DateTime Function() _now;
  final int cacheSize;
  final Duration cacheTtl;

  /// LRU: map literals are linked hash maps and keep insertion order, so re-inserting on hit moves
  /// an entry to the "most recent" end and the first key is the eviction
  /// candidate.
  final _cache = <String, _CachedPage>{};

  static const _related = 12;

  /// Explore shelves change slowly; keep them for the whole session start.
  static const _exploreTtl = Duration(minutes: 15);
  final _explore = <String, _CachedBooks>{};

  @override
  Future<BookSearchPage> search(
    String query, {
    int page = 1,
    String? language,
  }) async {
    final normalized = normalizeQuery(query);
    final scoped = _withLanguage(normalized, language);
    final key = '${scoped.toLowerCase()}|$page';

    final hit = _cache.remove(key);
    if (hit != null && _now().difference(hit.storedAt) < cacheTtl) {
      _cache[key] = hit;
      return hit.page;
    }

    try {
      final result = await _remote.search(scoped, page: page);
      _cache[key] = _CachedPage(result, _now());
      while (_cache.length > cacheSize) {
        _cache.remove(_cache.keys.first);
      }
      return result;
    } catch (e) {
      throw mapError(e);
    }
  }

  @override
  Future<Book?> findByIsbn(String isbn) async {
    final page = await search('isbn:$isbn');
    // The search index carries the work's rating and subjects; the edition
    // record is the fallback for editions it has not indexed yet.
    return page.books.firstOrNull ??
        await _guard(() => _remote.fetchByIsbn(isbn));
  }

  @override
  Future<Book?> findByWorkId(String workId) async {
    final page = await search('key:/works/$workId');
    return page.books.where((b) => b.externalId == workId).firstOrNull;
  }

  @override
  Future<ReaderActivity> getReaderActivity(Book book) => _guard(
        () => _remote.fetchReaderActivity(book.externalId),
      );

  @override
  Future<Book> getBookDetails(Book book) => _guard(
        () => _remote.fetchDetails(book),
      );

  @override
  Future<List<BookEdition>> getEditions(Book book) async {
    final editions = await _guard(() => _remote.fetchEditions(book.externalId));
    // Stable sort: equally complete editions keep Open Library's order.
    final indexed = [for (final (i, e) in editions.indexed) (i, e)]
      ..sort((a, b) {
        final byData = b.$2.completeness.compareTo(a.$2.completeness);
        return byData != 0 ? byData : a.$1.compareTo(b.$1);
      });
    return [for (final pair in indexed) pair.$2];
  }

  @override
  Future<AuthorInfo?> getAuthor(String authorKey) => _guard(
        () => _remote.fetchAuthor(authorKey),
      );

  @override
  Future<List<Book>> getBooksByAuthor(
    String authorKey, {
    String? exclude,
  }) async {
    final books = await _guard(
      () => _remote.fetchBooksByAuthor(authorKey, limit: _related + 1),
    );
    return books.where((b) => b.externalId != exclude).take(_related).toList();
  }

  @override
  Future<List<Book>> getSimilarBooks(Book book) async {
    if (book.subjects.isEmpty) return const [];
    // Two subjects together narrow the match; a single very common subject
    // ("Fiction") would return the whole catalogue.
    final books = await _guard(
      () => _remote.fetchBooksBySubjects(
        book.subjects.take(2).toList(),
        limit: _related * 2,
      ),
    );
    return books
        .where((b) => b.externalId != book.externalId)
        .where((b) => !b.authorKeys.any(book.authorKeys.contains))
        .take(_related)
        .toList();
  }

  @override
  Future<List<Book>> getExploreSection(
    ExploreSection section, {
    int limit = 12,
    bool refresh = false,
  }) async {
    final key = '${section.name}|$limit';
    final hit = _explore[key];
    if (!refresh &&
        hit != null &&
        _now().difference(hit.storedAt) < _exploreTtl) {
      return hit.books;
    }
    // Trending may include titles without artwork; ask for a few extra.
    final books = await _guard(
      () => _remote.fetchExplore(section, limit: limit + 6),
    );
    final withCover = books.where((b) => b.coverUrl != null);
    // Popular arrives as candidates: rating quality and vote count decide.
    final ordered = section == ExploreSection.popular
        ? BookRanking.rank(withCover)
        : withCover;
    final result = ordered.take(limit).toList();
    _explore[key] = _CachedBooks(result, _now());
    return result;
  }

  @override
  Future<List<Book>> getTopByGenre(
    ExploreGenre genre, {
    int limit = 20,
    bool refresh = false,
  }) async {
    final key = 'genre:${genre.name}|$limit';
    final hit = _explore[key];
    if (!refresh &&
        hit != null &&
        _now().difference(hit.storedAt) < _exploreTtl) {
      return hit.books;
    }
    // Open Library already orders by how many readers shelved each book.
    final result =
        await _guard(() => _remote.fetchTopByGenre(genre, limit: limit));
    _explore[key] = _CachedBooks(result, _now());
    return result;
  }

  Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } catch (e) {
      throw mapError(e);
    }
  }

  /// ISBN lookups are already exact; a language would only risk hiding them.
  static String _withLanguage(String query, String? language) {
    if (language == null || query.startsWith('isbn:')) return query;
    return '($query) AND language:$language';
  }

  static final _spaces = RegExp(r'\s+');
  static final _isbnChars = RegExp(r'^[\d\- ]+[\dXx]?$');

  /// Collapses whitespace and turns a pasted ISBN ("978-0-441-17271-9") into
  /// an exact `isbn:` query, which is faster and far more precise than a
  /// free-text match on the digits.
  static String normalizeQuery(String query) {
    final text = query.trim().replaceAll(_spaces, ' ');
    if (_isbnChars.hasMatch(text)) {
      final digits = text.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
      if (digits.length == 10 || digits.length == 13) return 'isbn:$digits';
    }
    return text;
  }
}

class _CachedPage {
  const _CachedPage(this.page, this.storedAt);

  final BookSearchPage page;
  final DateTime storedAt;
}

class _CachedBooks {
  const _CachedBooks(this.books, this.storedAt);

  final List<Book> books;
  final DateTime storedAt;
}
