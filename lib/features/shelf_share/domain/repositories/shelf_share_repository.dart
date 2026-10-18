import '../entities/shared_shelf.dart';
import '../entities/shelf_share.dart';

abstract interface class ShelfShareRepository {
  /// The current link for one of the user's shelves, or null if not shared.
  Future<ShelfShare?> shareFor(String shelfName);

  /// Starts sharing [shelfName] with a new link.
  Future<ShelfShare> create(String shelfName);

  /// Stops sharing [shelfName]: its link no longer works.
  Future<void> revoke(String shelfName);

  /// The shelf behind [token], or null when the link is unknown or revoked.
  Future<SharedShelf?> fetchShared(String token);
}
