import '../../domain/entities/user_book.dart';
import '../mappers/user_book_mapper.dart';

/// An edit made while offline, waiting to be sent. Only the latest change
/// per book is kept: an update carries every editable field, so it replaces
/// any earlier one.
sealed class PendingChange {
  const PendingChange(this.id);

  final String id;

  Map<String, dynamic> toJson();

  static PendingChange? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String) return null;
    switch (json['op']) {
      case 'delete':
        return PendingDelete(id);
      case 'update':
        final book = json['book'];
        if (book is! Map<String, dynamic>) return null;
        return PendingUpdate(UserBookMapper.fromJson(book));
    }
    return null;
  }
}

final class PendingUpdate extends PendingChange {
  PendingUpdate(this.book) : super(book.id);

  final UserBook book;

  @override
  Map<String, dynamic> toJson() =>
      {'op': 'update', 'id': id, 'book': UserBookMapper.toCacheJson(book)};
}

final class PendingDelete extends PendingChange {
  const PendingDelete(super.id);

  @override
  Map<String, dynamic> toJson() => {'op': 'delete', 'id': id};
}
