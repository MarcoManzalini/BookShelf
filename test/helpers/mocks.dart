import 'package:bookshelf/features/auth/domain/repositories/auth_repository.dart';
import 'package:bookshelf/features/library/domain/repositories/library_repository.dart';
import 'package:bookshelf/features/library/domain/usecases/add_book_to_library.dart';
import 'package:bookshelf/features/search/domain/repositories/book_search_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockLibraryRepository extends Mock implements LibraryRepository {}

class MockBookSearchRepository extends Mock implements BookSearchRepository {}

class MockAddBookToLibrary extends Mock implements AddBookToLibrary {}
