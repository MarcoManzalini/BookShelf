import '../../domain/entities/author_info.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/book_edition.dart';

class OpenLibraryMapper {
  const OpenLibraryMapper._();

  static const _coversBase = 'https://covers.openlibrary.org/b/id';
  static const _maxSubjects = 10;
  static const _maxExtraImages = 4;

  static String coverUrl(int coverId) =>
      '$_coversBase/$coverId-L.jpg?default=false';

  static String authorPhotoUrl(int photoId) =>
      'https://covers.openlibrary.org/a/id/$photoId-M.jpg?default=false';

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
      authorKeys: _strings(doc['author_key']),
      ratingAverage: _rating(doc['ratings_average']),
      ratingsCount: _positiveInt(doc['ratings_count']),
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
      authorKeys: base.authorKeys.isEmpty ? _workAuthorKeys(work) : null,
    );
  }

  /// `authors` is a list of `{author: {key: '/authors/OL1A'}, type: ...}`.
  static List<String> _workAuthorKeys(Map<String, dynamic> work) {
    final roles = work['authors'];
    if (roles is! List) return const [];
    return roles
        .whereType<Map<String, dynamic>>()
        .map((role) => (role['author'] as Map<String, dynamic>?)?['key'])
        .whereType<String>()
        .map((key) => key.split('/').last)
        .toList();
  }

  /// Merges `/works/{id}/ratings.json` into [base]; keeps [base] when nobody
  /// voted yet.
  static Book applyRatings(Book base, Map<String, dynamic> json) {
    final summary = json['summary'];
    if (summary is! Map<String, dynamic>) return base;
    final count = _positiveInt(summary['count']);
    final average = _rating(summary['average']);
    if (count == null || average == null) return base;
    return base.copyWith(ratingAverage: average, ratingsCount: count);
  }

  /// [author] is `/authors/{id}.json`; [workCount] comes from `.../works.json`.
  static AuthorInfo? authorFromJson(
    Map<String, dynamic> author, {
    int? workCount,
  }) {
    final key = (author['key'] as String?)?.split('/').last;
    final name = (author['name'] as String?)?.trim();
    if (key == null || name == null || name.isEmpty) return null;

    final photoId = (author['photos'] as List<dynamic>? ?? const [])
        .whereType<int>()
        .where((id) => id > 0)
        .firstOrNull;
    return AuthorInfo(
      key: key,
      name: name,
      bio: _cleanBio(_description(author['bio'])),
      birthDate: _nonBlank(author['birth_date']),
      deathDate: _nonBlank(author['death_date']),
      photoUrl: photoId == null ? null : authorPhotoUrl(photoId),
      workCount: workCount,
      wikipediaUrl: _nonBlank(author['wikipedia']),
    );
  }

  /// Open Library bios often end with a `----------` rule followed by
  /// "Source:" links and wiki noise.
  static String? _cleanBio(String? bio) {
    final head = bio?.split(RegExp(r'\n\s*-{3,}')).first.trim();
    return (head == null || head.isEmpty) ? null : head;
  }

  /// An entry of `/works/{id}/editions.json`; null without a usable key.
  static BookEdition? editionFromJson(Map<String, dynamic> json) {
    final key = (json['key'] as String?)?.split('/').last;
    if (key == null || key.isEmpty) return null;

    final isbns13 = _strings(json['isbn_13']);
    final isbns10 = _strings(json['isbn_10']);
    final languages = (json['languages'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((l) => (l['key'] as String?)?.split('/').last)
        .whereType<String>();
    final coverId = (json['covers'] as List<dynamic>? ?? const [])
        .whereType<int>()
        .where((id) => id > 0)
        .firstOrNull;
    return BookEdition(
      key: key,
      title: _nonBlank(json['title']),
      publisher: _strings(json['publishers']).firstOrNull?.trim(),
      publishedYear: _yearIn(json['publish_date']),
      pageCount: _positiveInt(json['number_of_pages']),
      isbn: isbns13.firstOrNull ?? isbns10.firstOrNull,
      language: languages.firstOrNull,
      coverUrl: coverId == null ? null : coverUrl(coverId),
      format: _nonBlank(json['physical_format']),
    );
  }

  static final _year = RegExp(r'\b(1[0-9]{3}|20[0-9]{2})\b');

  static int? _yearIn(Object? raw) => raw is String
      ? int.tryParse(_year.firstMatch(raw)?.group(1) ?? '')
      : null;

  static String? _nonBlank(Object? raw) {
    final text = raw is String ? raw.trim() : null;
    return (text == null || text.isEmpty) ? null : text;
  }

  static double? _rating(Object? raw) {
    final value = raw is num ? raw.toDouble() : null;
    return (value != null && value > 0) ? value : null;
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
