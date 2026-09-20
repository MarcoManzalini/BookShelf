import '../../../search/domain/entities/book.dart';
import '../entities/reading_status.dart';
import '../entities/user_book.dart';

abstract interface class LibraryRepository {
  /// Emits the full list whenever it changes (add, update, remove, refresh).
  Stream<List<UserBook>> get books;

  List<UserBook> get cachedBooks;

  UserBook? findCachedByExternalId(String externalId);

  /// Loads from the backend and refreshes the cache. Throws [Failure].
  Future<List<UserBook>> fetchAll();

  Future<UserBook?> getById(String id);

  Future<UserBook> add(Book book, ReadingStatus status);

  Future<UserBook> update(UserBook book);

  Future<void> remove(String id);

  /// Drops the cache (used on logout) without emitting.
  void clear();
}
