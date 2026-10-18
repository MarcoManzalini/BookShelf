import '../../../library/domain/entities/reading_status.dart';
import '../../../library/domain/entities/shelf_names.dart';
import '../../../library/domain/repositories/library_repository.dart';
import '../entities/shared_shelf.dart';

/// Copies a shared shelf into the reader's library: missing books are added
/// as "want to read", every book gets the shelf tag. The copy does not follow
/// later changes to the original.
class SaveSharedShelf {
  const SaveSharedShelf(this._library);

  final LibraryRepository _library;

  /// Returns how many books were new to the library.
  Future<int> call(SharedShelf shelf) async {
    // Opened from a link on a cold start, the library may not be loaded yet:
    // without it owned books would be added again and fail.
    if (_library.cachedBooks.isEmpty) await _library.fetchAll();
    final name = _readerSpelling(shelf.shelfName);
    var added = 0;
    for (final book in shelf.books) {
      final owned = _library.findCachedByExternalId(book.externalId);
      if (owned == null) {
        final created = await _library.add(book, ReadingStatus.wantToRead);
        await _library.update(created.copyWith(shelves: [name]));
        added++;
        continue;
      }
      final shelves = owned.shelves;
      if (shelves.any((s) => ShelfNames.same(s, name))) continue;
      if (shelves.length >= ShelfNames.maxPerBook) continue;
      await _library.update(owned.copyWith(shelves: [...shelves, name]));
    }
    return added;
  }

  /// The reader's own spelling when they already have a shelf by this name.
  String _readerSpelling(String shelfName) {
    for (final book in _library.cachedBooks) {
      for (final shelf in book.shelves) {
        if (ShelfNames.same(shelf, shelfName)) return shelf;
      }
    }
    return shelfName;
  }
}
