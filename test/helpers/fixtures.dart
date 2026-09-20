import 'package:bookshelf/features/auth/domain/entities/app_user.dart';
import 'package:bookshelf/features/library/domain/entities/reading_status.dart';
import 'package:bookshelf/features/library/domain/entities/user_book.dart';
import 'package:bookshelf/features/search/domain/entities/book.dart';

const testUser = AppUser(id: 'user-1', email: 'reader@example.com');

Book buildBook({
  String id = 'OL1W',
  String title = 'Dune',
  int? pageCount = 400,
  String? description,
}) {
  return Book(
    externalId: id,
    title: title,
    authors: const ['Frank Herbert'],
    pageCount: pageCount,
    publishedYear: 1965,
    description: description,
  );
}

UserBook buildUserBook({
  String id = 'ub-1',
  Book? book,
  ReadingStatus status = ReadingStatus.wantToRead,
  int currentPage = 0,
  int? rating,
  DateTime? startedAt,
  DateTime? finishedAt,
}) {
  return UserBook(
    id: id,
    book: book ?? buildBook(),
    status: status,
    currentPage: currentPage,
    rating: rating,
    startedAt: startedAt,
    finishedAt: finishedAt,
    createdAt: DateTime(2024, 1, 1),
  );
}
