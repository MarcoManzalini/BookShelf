import '../../../search/domain/entities/book.dart';
import '../entities/reading_status.dart';
import '../entities/sync_status.dart';
import '../entities/user_book.dart';

abstract interface class LibraryRepository {
  /// Emits the full list whenever it changes (add, update, remove, refresh).
  Stream<List<UserBook>> get books;

  List<UserBook> get cachedBooks;

  /// Emits when the connection state or the number of unsent edits changes.
  Stream<SyncStatus> get syncStatus;

  SyncStatus get currentSync;

  UserBook? findCachedByExternalId(String externalId);

  /// Loads from the backend and refreshes the cache, first sending any edits
  /// made offline. Without a connection it serves the saved copy instead of
  /// failing, if there is one. Throws [Failure] otherwise.
  Future<List<UserBook>> fetchAll();

  Future<UserBook?> getById(String id);

  Future<UserBook> add(Book book, ReadingStatus status);

  /// Saves an edit. Without a connection the edit is kept on the device and
  /// sent later (see [syncStatus]); the returned book is then the local one.
  Future<UserBook> update(UserBook book);

  /// Removes a book; like [update], it waits for a connection if needed.
  Future<void> remove(String id);

  /// Drops the cache (used on logout) without emitting.
  void clear();
}
