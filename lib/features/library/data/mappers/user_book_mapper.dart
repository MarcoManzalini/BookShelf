import '../../../search/domain/entities/book.dart';
import '../../domain/entities/book_format.dart';
import '../../domain/entities/book_loan.dart';
import '../../domain/entities/book_read.dart';
import '../../domain/entities/book_series.dart';
import '../../domain/entities/book_vibe.dart';
import '../../domain/entities/reading_status.dart';
import '../../domain/entities/user_book.dart';

class UserBookMapper {
  const UserBookMapper._();

  static UserBook fromJson(Map<String, dynamic> json) {
    return UserBook(
      id: json['id'] as String,
      book: Book(
        externalId: json['external_id'] as String,
        title: json['title'] as String,
        authors: _stringList(json['authors']),
        coverUrl: json['cover_url'] as String?,
        description: json['description'] as String?,
        isbn: json['isbn'] as String?,
        pageCount: json['page_count'] as int?,
        publisher: json['publisher'] as String?,
        publishedYear: json['published_year'] as int?,
        subjects: _stringList(json['subjects']),
        language: json['language'] as String?,
        editionKey: json['edition_key'] as String?,
      ),
      shelves: _stringList(json['shelves']),
      pastReads: _reads(json['past_reads']),
      format: BookFormat.fromDb(json['format'] as String?),
      durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
      series: _series(json),
      moods: BookMood.fromDb(_stringList(json['moods'])),
      pace: ReadingPace.fromDb(json['pace'] as String?),
      loan: _loan(json),
      status: ReadingStatus.fromDb(json['status'] as String),
      currentPage: (json['current_page'] as int?) ?? 0,
      rating: json['rating'] as int?,
      notes: json['notes'] as String?,
      startedAt: _parseDate(json['started_at']),
      finishedAt: _parseDate(json['finished_at']),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static Map<String, dynamic> toInsertJson(Book book, ReadingStatus status) {
    return {
      'external_id': book.externalId,
      'title': book.title,
      'authors': book.authors,
      'cover_url': book.coverUrl,
      'description': book.description,
      'isbn': book.isbn,
      'page_count': book.pageCount,
      'publisher': book.publisher,
      'published_year': book.publishedYear,
      'subjects': book.subjects,
      'language': book.language,
      'edition_key': book.editionKey,
      'status': status.dbValue,
    };
  }

  static Map<String, dynamic> toUpdateJson(UserBook book) {
    return {
      'status': book.status.dbValue,
      'current_page': book.currentPage,
      'rating': book.rating,
      'notes': book.notes,
      'started_at': _formatDate(book.startedAt),
      'finished_at': _formatDate(book.finishedAt),
      'shelves': book.shelves,
      'past_reads': [for (final r in book.pastReads) r.toJson()],
      'format': book.format.dbValue,
      'duration_minutes': book.durationMinutes,
      'series_name': book.series?.name,
      'series_index': book.series?.index,
      'series_index_end': book.series?.indexEnd,
      'series_total': book.series?.total,
      'moods': [for (final m in book.moods) m.dbValue],
      'pace': book.pace?.dbValue,
      'loan_kind': book.loan?.kind.dbValue,
      'loan_person': book.loan?.person,
      'loan_since': _formatDate(book.loan?.since),
      'loan_due': _formatDate(book.loan?.due),
      // The reader can switch edition, which changes these book fields.
      'isbn': book.book.isbn,
      'page_count': book.book.pageCount,
      'publisher': book.book.publisher,
      'published_year': book.book.publishedYear,
      'cover_url': book.book.coverUrl,
      'language': book.book.language,
      'edition_key': book.book.editionKey,
    };
  }

  /// The full row as the server would return it: what the offline cache
  /// stores, read back by [fromJson].
  static Map<String, dynamic> toCacheJson(UserBook userBook) {
    final book = userBook.book;
    return {
      'id': userBook.id,
      'external_id': book.externalId,
      'title': book.title,
      'authors': book.authors,
      'cover_url': book.coverUrl,
      'description': book.description,
      'isbn': book.isbn,
      'page_count': book.pageCount,
      'publisher': book.publisher,
      'published_year': book.publishedYear,
      'subjects': book.subjects,
      'language': book.language,
      'edition_key': book.editionKey,
      'status': userBook.status.dbValue,
      'current_page': userBook.currentPage,
      'rating': userBook.rating,
      'notes': userBook.notes,
      'started_at': _formatDate(userBook.startedAt),
      'finished_at': _formatDate(userBook.finishedAt),
      'created_at': userBook.createdAt.toIso8601String(),
      'shelves': userBook.shelves,
      'past_reads': [for (final r in userBook.pastReads) r.toJson()],
      'format': userBook.format.dbValue,
      'duration_minutes': userBook.durationMinutes,
      'series_name': userBook.series?.name,
      'series_index': userBook.series?.index,
      'series_index_end': userBook.series?.indexEnd,
      'series_total': userBook.series?.total,
      'moods': [for (final m in userBook.moods) m.dbValue],
      'pace': userBook.pace?.dbValue,
      'loan_kind': userBook.loan?.kind.dbValue,
      'loan_person': userBook.loan?.person,
      'loan_since': _formatDate(userBook.loan?.since),
      'loan_due': _formatDate(userBook.loan?.due),
    };
  }

  static List<String> _stringList(Object? raw) =>
      raw is List ? raw.whereType<String>().toList() : const [];

  static BookSeries? _series(Map<String, dynamic> json) {
    final name = json['series_name'] as String?;
    if (name == null || name.trim().isEmpty) return null;
    return BookSeries(
      name: name,
      index: (json['series_index'] as num?)?.toDouble(),
      indexEnd: (json['series_index_end'] as num?)?.toDouble(),
      total: (json['series_total'] as num?)?.toInt(),
    );
  }

  static BookLoan? _loan(Map<String, dynamic> json) {
    final kind = LoanKind.fromDb(json['loan_kind'] as String?);
    final person = json['loan_person'] as String?;
    final since = _parseDate(json['loan_since']);
    if (kind == null || person == null || since == null) return null;
    return BookLoan(
      kind: kind,
      person: person,
      since: since,
      due: _parseDate(json['loan_due']),
    );
  }

  static List<BookRead> _reads(Object? raw) => raw is List
      ? [
          for (final item in raw)
            if (item is Map) BookRead.fromJson(item.cast<String, dynamic>()),
        ]
      : const [];

  static DateTime? _parseDate(Object? raw) =>
      raw is String ? DateTime.parse(raw) : null;

  static String? _formatDate(DateTime? date) {
    if (date == null) return null;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }
}
