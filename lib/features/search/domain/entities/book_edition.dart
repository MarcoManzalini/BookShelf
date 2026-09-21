import 'package:equatable/equatable.dart';

import 'book.dart';

/// One published edition of a work: the level at which page count, ISBN,
/// publisher, language and cover are actually accurate.
class BookEdition extends Equatable {
  const BookEdition({
    required this.key,
    this.title,
    this.publisher,
    this.publishedYear,
    this.pageCount,
    this.isbn,
    this.language,
    this.coverUrl,
    this.format,
  });

  /// Open Library edition id, e.g. `OL62445412M`.
  final String key;
  final String? title;
  final String? publisher;
  final int? publishedYear;
  final int? pageCount;
  final String? isbn;

  /// Three-letter code (`ita`, `eng`).
  final String? language;
  final String? coverUrl;
  final String? format;

  /// Editions with more data first: they are the ones worth picking.
  int get completeness =>
      (isbn != null ? 1 : 0) +
      (pageCount != null ? 1 : 0) +
      (coverUrl != null ? 1 : 0) +
      (publisher != null ? 1 : 0) +
      (publishedYear != null ? 1 : 0);

  /// [book] with this edition's details; missing ones keep the book's own.
  Book applyTo(Book book) => book.copyWith(
        editionKey: key,
        isbn: isbn,
        pageCount: pageCount,
        publisher: publisher,
        publishedYear: publishedYear,
        language: language,
        coverUrl: coverUrl,
      );

  @override
  List<Object?> get props => [
        key,
        title,
        publisher,
        publishedYear,
        pageCount,
        isbn,
        language,
        coverUrl,
        format,
      ];
}
