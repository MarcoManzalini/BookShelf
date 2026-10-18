import '../../../search/domain/entities/book.dart';
import '../../domain/entities/shared_shelf.dart';
import '../../domain/entities/shelf_share.dart';

abstract final class ShelfShareMapper {
  static ShelfShare shareFromJson(Map<String, dynamic> json) => ShelfShare(
        shelfName: json['shelf_name'] as String,
        token: json['token'] as String,
      );

  /// Reads the payload of the `get_shared_shelf` RPC.
  static SharedShelf sharedFromJson(Map<String, dynamic> json) {
    final books = (json['books'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(_bookFromJson)
        .toList();
    return SharedShelf(
      shelfName: json['shelf_name'] as String,
      ownerName: json['owner_name'] as String?,
      books: books,
    );
  }

  static Book _bookFromJson(Map<String, dynamic> json) => Book(
        externalId: json['external_id'] as String,
        title: json['title'] as String,
        authors: (json['authors'] as List<dynamic>? ?? const [])
            .cast<String>()
            .toList(),
        coverUrl: json['cover_url'] as String?,
        publishedYear: (json['published_year'] as num?)?.toInt(),
      );
}
