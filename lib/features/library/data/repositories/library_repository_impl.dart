import 'dart:async';

import '../../../../core/errors/error_mapper.dart';
import '../../../search/domain/entities/book.dart';
import '../../domain/entities/reading_status.dart';
import '../../domain/entities/user_book.dart';
import '../../domain/repositories/library_repository.dart';
import '../datasources/library_remote_data_source.dart';

class LibraryRepositoryImpl implements LibraryRepository {
  LibraryRepositoryImpl(this._remote);

  final LibraryRemoteDataSource _remote;
  final _controller = StreamController<List<UserBook>>.broadcast();
  List<UserBook> _books = const [];

  @override
  Stream<List<UserBook>> get books => _controller.stream;

  @override
  List<UserBook> get cachedBooks => _books;

  @override
  UserBook? findCachedByExternalId(String externalId) {
    for (final b in _books) {
      if (b.book.externalId == externalId) return b;
    }
    return null;
  }

  @override
  Future<List<UserBook>> fetchAll() async {
    try {
      final books = await _remote.fetchAll();
      _publish(books);
      return _books;
    } catch (e) {
      throw mapError(e);
    }
  }

  @override
  Future<UserBook?> getById(String id) async {
    for (final b in _books) {
      if (b.id == id) return b;
    }
    try {
      return await _remote.fetchById(id);
    } catch (e) {
      throw mapError(e);
    }
  }

  @override
  Future<UserBook> add(Book book, ReadingStatus status) async {
    final existing = findCachedByExternalId(book.externalId);
    if (existing != null) return existing;
    try {
      final created = await _remote.insert(book, status);
      _publish([created, ..._books]);
      return created;
    } catch (e) {
      throw mapError(e);
    }
  }

  @override
  Future<UserBook> update(UserBook book) async {
    try {
      final saved = await _remote.update(book);
      _publish([for (final b in _books) b.id == saved.id ? saved : b]);
      return saved;
    } catch (e) {
      throw mapError(e);
    }
  }

  @override
  Future<void> remove(String id) async {
    try {
      await _remote.delete(id);
      _publish(_books.where((b) => b.id != id).toList());
    } catch (e) {
      throw mapError(e);
    }
  }

  @override
  void clear() => _books = const [];

  void _publish(List<UserBook> books) {
    _books = List.unmodifiable(books);
    _controller.add(_books);
  }
}
