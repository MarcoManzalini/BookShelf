import 'package:equatable/equatable.dart';

import 'book.dart';

class BookSearchPage extends Equatable {
  const BookSearchPage({
    required this.books,
    required this.page,
    required this.hasMore,
  });

  final List<Book> books;
  final int page;
  final bool hasMore;

  @override
  List<Object?> get props => [books, page, hasMore];
}
