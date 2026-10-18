import 'package:equatable/equatable.dart';

import '../../../search/domain/entities/book.dart';

/// A shelf someone shared, as the people with the link see it: only the
/// books, never the owner's ratings, notes or progress.
class SharedShelf extends Equatable {
  const SharedShelf({
    required this.shelfName,
    this.ownerName,
    required this.books,
  });

  final String shelfName;
  final String? ownerName;
  final List<Book> books;

  @override
  List<Object?> get props => [shelfName, ownerName, books];
}
