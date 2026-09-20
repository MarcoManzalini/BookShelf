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
  }) {
    return Book(
      externalId: externalId,
      title: title,
      authors: authors,
      coverUrl: coverUrl ?? this.coverUrl,
      extraImages: extraImages ?? this.extraImages,
      description: description ?? this.description,
      isbn: isbn,
      pageCount: pageCount,
      publisher: publisher,
      publishedYear: publishedYear,
      subjects: subjects ?? this.subjects,
      language: language,
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
      ];
}
