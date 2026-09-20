import '../../../search/domain/entities/book.dart';
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
      ),
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
    };
  }

  static List<String> _stringList(Object? raw) =>
      raw is List ? raw.whereType<String>().toList() : const [];

  static DateTime? _parseDate(Object? raw) =>
      raw is String ? DateTime.parse(raw) : null;

  static String? _formatDate(DateTime? date) {
    if (date == null) return null;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }
}
