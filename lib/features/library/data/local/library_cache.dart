import 'dart:convert';
import 'dart:io';

import '../../domain/entities/user_book.dart';
import '../mappers/user_book_mapper.dart';
import 'pending_change.dart';

/// What the app remembers between runs so the library works without a
/// connection: the books as last seen, and the edits not yet sent.
class LibrarySnapshot {
  const LibrarySnapshot({
    required this.userId,
    required this.books,
    this.pending = const [],
  });

  final String userId;
  final List<UserBook> books;
  final List<PendingChange> pending;

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'books': [for (final b in books) UserBookMapper.toCacheJson(b)],
        'pending': [for (final p in pending) p.toJson()],
      };

  /// Null when [json] is not a snapshot this version understands.
  static LibrarySnapshot? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final userId = json['userId'];
    final books = json['books'];
    if (userId is! String || books is! List) return null;
    try {
      return LibrarySnapshot(
        userId: userId,
        books: [
          for (final b in books.whereType<Map<String, dynamic>>())
            UserBookMapper.fromJson(b),
        ],
        pending: (json['pending'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(PendingChange.fromJson)
            .nonNulls
            .toList(),
      );
    } catch (_) {
      return null;
    }
  }
}

abstract interface class LibraryCache {
  Future<LibrarySnapshot?> read();
  Future<void> write(LibrarySnapshot snapshot);
  Future<void> clear();
}

/// JSON file in the app's private storage.
class FileLibraryCache implements LibraryCache {
  FileLibraryCache(this._file);

  /// Resolves the file lazily: `path_provider` is only available at runtime.
  final Future<File> Function() _file;

  @override
  Future<LibrarySnapshot?> read() async {
    try {
      final file = await _file();
      if (!await file.exists()) return null;
      return LibrarySnapshot.fromJson(jsonDecode(await file.readAsString()));
    } catch (_) {
      // A corrupt cache is the same as no cache.
      return null;
    }
  }

  @override
  Future<void> write(LibrarySnapshot snapshot) async {
    try {
      final file = await _file();
      // Write-then-rename so a crash mid-write never leaves a broken file.
      final temp = File('${file.path}.tmp');
      await temp.writeAsString(jsonEncode(snapshot.toJson()), flush: true);
      await temp.rename(file.path);
    } catch (_) {
      // The cache is an optimisation: never fail the real operation for it.
    }
  }

  @override
  Future<void> clear() async {
    try {
      final file = await _file();
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
