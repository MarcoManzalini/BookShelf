import '../../domain/entities/book_quote.dart';

class BookQuoteMapper {
  const BookQuoteMapper._();

  static BookQuote fromJson(Map<String, dynamic> json) => BookQuote(
        id: json['id'] as String,
        userBookId: json['user_book_id'] as String,
        text: json['text'] as String,
        page: (json['page'] as num?)?.toInt(),
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  static Map<String, dynamic> toInsertJson({
    required String userBookId,
    required String text,
    int? page,
  }) =>
      {'user_book_id': userBookId, 'text': text, 'page': page};

  static Map<String, dynamic> toUpdateJson(BookQuote quote) =>
      {'text': quote.text, 'page': quote.page};
}
