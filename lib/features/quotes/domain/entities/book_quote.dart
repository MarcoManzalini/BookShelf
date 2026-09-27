import 'package:equatable/equatable.dart';

/// A passage the reader saved from a book.
class BookQuote extends Equatable {
  const BookQuote({
    required this.id,
    required this.userBookId,
    required this.text,
    required this.createdAt,
    this.page,
  });

  /// Longest passage that can be saved.
  static const maxLength = 2000;

  final String id;
  final String userBookId;
  final String text;

  /// Page the passage is on, when the reader noted it.
  final int? page;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, userBookId, text, page, createdAt];
}
