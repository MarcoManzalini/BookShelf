import 'package:dio/dio.dart';

import '../../library/domain/entities/reading_status.dart';
import '../domain/import_row.dart';

enum ReadingLogError {
  /// No Open Library account with that username.
  userNotFound,

  /// The account keeps its reading log private.
  private,

  /// The reading log has no books.
  empty,

  /// Open Library could not be reached.
  network,
}

class ReadingLogException implements Exception {
  const ReadingLogException(this.error);

  final ReadingLogError error;

  @override
  String toString() => 'ReadingLogException($error)';
}

/// Reads a public Open Library reading log (`/people/{username}/books/...`):
/// no login is needed as long as the reader made the log public.
class OpenLibraryReadingLog {
  OpenLibraryReadingLog(this._dio);

  final Dio _dio;

  static const _shelves = {
    'want-to-read': ReadingStatus.wantToRead,
    'currently-reading': ReadingStatus.reading,
    'already-read': ReadingStatus.read,
  };

  /// A safety stop for very large logs; pages hold up to 100 books.
  static const _maxPages = 50;

  static final _username = RegExp(r'^[A-Za-z0-9_.\-]{1,100}$');

  /// The username from what the reader typed: the name itself, "@name" or
  /// the profile address (`openlibrary.org/people/name`). Null when invalid.
  static String? parseUsername(String input) {
    var text = input.trim();
    final profile = RegExp(r'/people/([^/?#\s]+)').firstMatch(text);
    if (profile != null) text = profile.group(1)!;
    if (text.startsWith('@')) text = text.substring(1);
    return _username.hasMatch(text) ? text : null;
  }

  /// Throws [ReadingLogException].
  Future<List<ImportRow>> fetch(String username) async {
    final rows = <ImportRow>[];
    for (final MapEntry(key: shelf, value: status) in _shelves.entries) {
      rows.addAll(await _fetchShelf(username, shelf, status));
    }
    if (rows.isEmpty) throw const ReadingLogException(ReadingLogError.empty);
    return rows;
  }

  Future<List<ImportRow>> _fetchShelf(
    String username,
    String shelf,
    ReadingStatus status,
  ) async {
    final rows = <ImportRow>[];
    for (var page = 1; page <= _maxPages; page++) {
      final data = await _get(
        '/people/${Uri.encodeComponent(username)}/books/$shelf.json',
        page,
      );
      final entries = (data['reading_log_entries'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();
      rows.addAll(entries.map((e) => rowFromEntry(e, status)).nonNulls);
      final total = (data['numFound'] as num?)?.toInt() ?? 0;
      if (entries.isEmpty || rows.length >= total) break;
    }
    return rows;
  }

  Future<Map<String, dynamic>> _get(String path, int page) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: {'page': page},
      );
      return response.data ?? const {};
    } on DioException catch (e) {
      throw ReadingLogException(
        switch (e.response?.statusCode) {
          404 => ReadingLogError.userNotFound,
          401 || 403 => ReadingLogError.private,
          _ => ReadingLogError.network,
        },
      );
    }
  }

  /// One `reading_log_entries` item; null without a work or a title.
  static ImportRow? rowFromEntry(
    Map<String, dynamic> entry,
    ReadingStatus status,
  ) {
    final work = entry['work'];
    if (work is! Map<String, dynamic>) return null;
    final title = (work['title'] as String?)?.trim();
    final workId = (work['key'] as String?)?.split('/').last;
    if (title == null || title.isEmpty || workId == null || workId.isEmpty) {
      return null;
    }
    final authors = (work['author_names'] as List<dynamic>? ?? [])
        .whereType<String>()
        .toList();
    return ImportRow(
      title: title,
      author: authors.isEmpty ? null : authors.join(', '),
      status: status,
      workId: workId,
      addedOn: _loggedDate(entry['logged_date']),
    );
  }

  /// "2025/09/23, 02:11:08" -> 2025-09-23.
  static DateTime? _loggedDate(Object? raw) {
    if (raw is! String) return null;
    final m = RegExp(r'^(\d{4})/(\d{2})/(\d{2})').firstMatch(raw);
    if (m == null) return null;
    return DateTime(
      int.parse(m.group(1)!),
      int.parse(m.group(2)!),
      int.parse(m.group(3)!),
    );
  }
}
