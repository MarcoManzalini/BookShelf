import 'package:equatable/equatable.dart';

class Book extends Equatable {
  const Book({
    required this.externalId,
    required this.title,
    this.authors = const [],
    this.coverUrl,
    this.extraImages = const [],
    this.description,
    this.isbn,
    this.pageCount,
    this.publisher,
    this.publishedYear,
    this.subjects = const [],
    this.language,
    this.authorKeys = const [],
    this.ratingAverage,
    this.ratingsCount,
    this.editionKey,
  });

  /// Open Library work id, e.g. `OL45804W`.
  final String externalId;
  final String title;
  final List<String> authors;
  final String? coverUrl;

  /// Additional images (spine, back cover, ...). Open Library does not offer
  /// these reliably, so this only holds extra covers when the API returns any.
  final List<String> extraImages;
  final String? description;
  final String? isbn;
  final int? pageCount;
  final String? publisher;
  final int? publishedYear;
  final List<String> subjects;
  final String? language;

  /// Open Library author ids (`OL79034A`), parallel to [authors] when known.
  /// Not stored in the library: loaded again from the work when needed.
  final List<String> authorKeys;

  /// Community rating from Open Library (0-5) and the number of votes.
  final double? ratingAverage;
  final int? ratingsCount;

  /// Open Library edition the reader picked (`OL123M`); null = work default.
  final String? editionKey;

  bool get hasCommunityRating =>
      ratingAverage != null && (ratingsCount ?? 0) > 0;

  String get authorsLabel => authors.join(', ');

  /// Every image available for the details carousel, cover first.
  List<String> get images => [
        if (coverUrl != null) coverUrl!,
        ...extraImages,
      ];

  Book copyWith({
    String? description,
    List<String>? extraImages,
    List<String>? subjects,
    String? coverUrl,
    List<String>? authorKeys,
    double? ratingAverage,
    int? ratingsCount,
    String? isbn,
    int? pageCount,
    String? publisher,
    int? publishedYear,
    String? language,
    String? editionKey,
  }) {
    return Book(
      externalId: externalId,
      title: title,
      authors: authors,
      coverUrl: coverUrl ?? this.coverUrl,
      extraImages: extraImages ?? this.extraImages,
      description: description ?? this.description,
      isbn: isbn ?? this.isbn,
      pageCount: pageCount ?? this.pageCount,
      publisher: publisher ?? this.publisher,
      publishedYear: publishedYear ?? this.publishedYear,
      subjects: subjects ?? this.subjects,
      language: language ?? this.language,
      authorKeys: authorKeys ?? this.authorKeys,
      ratingAverage: ratingAverage ?? this.ratingAverage,
      ratingsCount: ratingsCount ?? this.ratingsCount,
      editionKey: editionKey ?? this.editionKey,
    );
  }

  @override
  List<Object?> get props => [
        externalId,
        title,
        authors,
        coverUrl,
        extraImages,
        description,
        isbn,
        pageCount,
        publisher,
        publishedYear,
        subjects,
        language,
        authorKeys,
        ratingAverage,
        ratingsCount,
        editionKey,
      ];
}
