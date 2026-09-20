import '../../domain/entities/book.dart';

class OpenLibraryMapper {
  const OpenLibraryMapper._();

  static const _coversBase = 'https://covers.openlibrary.org/b/id';
  static const _maxSubjects = 10;
  static const _maxExtraImages = 4;

  static String coverUrl(int coverId) =>
      '$_coversBase/$coverId-L.jpg?default=false';

  /// Returns null when the document lacks the minimum data (key + title).
  static Book? bookFromSearchDoc(Map<String, dynamic> doc) {
    final key = doc['key'] as String?;
    final title = doc['title'] as String?;
    if (key == null || title == null || title.trim().isEmpty) return null;

    final coverId = doc['cover_i'];
    return Book(
      externalId: key.split('/').last,
      title: title.trim(),
      authors: _strings(doc['author_name']),
      coverUrl: coverId is int ? coverUrl(coverId) : null,
      isbn: _pickIsbn(_strings(doc['isbn'])),
      pageCount: _positiveInt(doc['number_of_pages_median']),
      publisher: _strings(doc['publisher']).firstOrNull,
      publishedYear: _positiveInt(doc['first_publish_year']),
      subjects: _strings(doc['subject']).take(_maxSubjects).toList(),
      language: _strings(doc['language']).firstOrNull,
    );
  }

  /// Merges `/works/{id}.json` data into [base].
  static Book applyWork(Book base, Map<String, dynamic> work) {
    final subjects = _strings(work['subjects']).take(_maxSubjects).toList();
    final coverIds = (work['covers'] as List<dynamic>? ?? const [])
        .whereType<int>()
        .where((id) => id > 0)
        .map(coverUrl)
        .where((url) => url != base.coverUrl)
        .take(_maxExtraImages)
        .toList();

    return base.copyWith(
      description: _description(work['description']) ?? base.description,
      subjects: base.subjects.isEmpty ? subjects : null,
      extraImages: coverIds,
      coverUrl: base.coverUrl ?? (coverIds.isNotEmpty ? coverIds.first : null),
    );
  }

  /// `description` is either a plain string or `{type, value}`.
  static String? _description(Object? raw) {
    final text = switch (raw) {
      final String s => s,
      final Map<String, dynamic> m => m['value'] as String?,
      _ => null,
    };
    final trimmed = text?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  static List<String> _strings(Object? raw) {
    if (raw is! List) return const [];
    return raw.whereType<String>().toList();
  }

  static int? _positiveInt(Object? raw) {
    final value = raw is num ? raw.toInt() : null;
    return (value != null && value > 0) ? value : null;
  }

  static String? _pickIsbn(List<String> isbns) {
    if (isbns.isEmpty) return null;
    return isbns.firstWhere((i) => i.length == 13, orElse: () => isbns.first);
  }
}
