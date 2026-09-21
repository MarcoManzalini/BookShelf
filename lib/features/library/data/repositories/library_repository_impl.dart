import 'dart:async';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failure.dart';
import '../../../search/domain/entities/book.dart';
import '../../domain/entities/reading_status.dart';
import '../../domain/entities/sync_status.dart';
import '../../domain/entities/user_book.dart';
import '../../domain/repositories/library_repository.dart';
import '../datasources/library_remote_data_source.dart';
import '../local/library_cache.dart';
import '../local/pending_change.dart';

/// Library backed by Supabase, with a saved copy on the device.
///
/// Offline behaviour: reading works from the saved copy; edits (progress,
/// status, rating, notes, shelves, edition, removal) are applied locally,
/// queued, and sent the next time the server answers. Adding a book needs the
/// server (it must create the row) and fails while offline.
class LibraryRepositoryImpl implements LibraryRepository {
  LibraryRepositoryImpl(
    this._remote, {
    LibraryCache? cache,
    String? Function()? currentUserId,
  })  : _cache = cache,
        _currentUserId = currentUserId;

  final LibraryRemoteDataSource _remote;
  final LibraryCache? _cache;
  final String? Function()? _currentUserId;

  final _controller = StreamController<List<UserBook>>.broadcast();
  final _syncController = StreamController<SyncStatus>.broadcast();
  List<UserBook> _books = const [];
  final _pending = <PendingChange>[];
  bool _offline = false;

  @override
  Stream<List<UserBook>> get books => _controller.stream;

  @override
  Stream<SyncStatus> get syncStatus => _syncController.stream;

  @override
  SyncStatus get currentSync =>
      SyncStatus(offline: _offline, pending: _pending.length);

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
    await _loadSavedCopyIfNeeded();
    try {
      await _flushPending();
      final remote = await _remote.fetchAll();
      // Edits that could not be sent yet must not vanish from the screen.
      _publish(_applyPending(remote));
      _setOffline(false);
      return _books;
    } catch (e) {
      final failure = mapError(e);
      if (_isConnectivity(failure) && _books.isNotEmpty) {
        _setOffline(true);
        _publish(_books);
        return _books;
      }
      if (_isConnectivity(failure)) _setOffline(true);
      throw failure;
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
      _setOffline(false);
      return created;
    } catch (e) {
      final failure = mapError(e);
      if (_isConnectivity(failure)) _setOffline(true);
      throw failure;
    }
  }

  @override
  Future<UserBook> update(UserBook book) async {
    try {
      final saved = await _remote.update(book);
      // The server now holds this state; an older queued edit would undo it.
      _pending.removeWhere((p) => p.id == book.id);
      _publish([for (final b in _books) b.id == saved.id ? saved : b]);
      _setOffline(false);
      return saved;
    } catch (e) {
      final failure = mapError(e);
      if (!_isConnectivity(failure)) throw failure;
      _queue(PendingUpdate(book));
      _publish([for (final b in _books) b.id == book.id ? book : b]);
      _setOffline(true);
      return book;
    }
  }

  @override
  Future<void> remove(String id) async {
    try {
      await _remote.delete(id);
      _pending.removeWhere((p) => p.id == id);
      _publish(_books.where((b) => b.id != id).toList());
      _setOffline(false);
    } catch (e) {
      final failure = mapError(e);
      if (!_isConnectivity(failure)) throw failure;
      _queue(PendingDelete(id));
      _publish(_books.where((b) => b.id != id).toList());
      _setOffline(true);
    }
  }

  @override
  void clear() {
    _books = const [];
    _pending.clear();
    _offline = false;
    // The saved copy belongs to the signed-out user.
    unawaited(_cache?.clear());
  }

  /// First call after launch: show the saved copy of the same user even
  /// before (or without) the network answering.
  Future<void> _loadSavedCopyIfNeeded() async {
    final cache = _cache;
    if (cache == null || _books.isNotEmpty || _pending.isNotEmpty) return;
    final snapshot = await cache.read();
    if (snapshot == null) return;
    final userId = _currentUserId?.call();
    if (userId == null || snapshot.userId != userId) {
      await cache.clear();
      return;
    }
    _books = List.unmodifiable(snapshot.books);
    _pending.addAll(snapshot.pending);
  }

  /// Sends queued edits in order. Stops at the first connectivity failure
  /// (keeping the rest); drops a change the server refuses for good.
  Future<void> _flushPending() async {
    while (_pending.isNotEmpty) {
      final change = _pending.first;
      try {
        switch (change) {
          case PendingUpdate(:final book):
            await _remote.update(book);
          case PendingDelete(:final id):
            await _remote.delete(id);
        }
      } catch (e) {
        final failure = mapError(e);
        if (_isConnectivity(failure)) rethrow;
        // Row gone, forbidden, invalid: retrying will not help.
      }
      _pending.removeAt(0);
      _emitSync();
    }
  }

  List<UserBook> _applyPending(List<UserBook> remote) {
    var books = remote;
    for (final change in _pending) {
      books = switch (change) {
        PendingUpdate(:final book) => [
            for (final b in books) b.id == book.id ? book : b,
          ],
        PendingDelete(:final id) => books.where((b) => b.id != id).toList(),
      };
    }
    return books;
  }

  void _queue(PendingChange change) {
    _pending
      ..removeWhere((p) => p.id == change.id)
      ..add(change);
    _emitSync();
  }

  void _setOffline(bool offline) {
    if (_offline == offline) return;
    _offline = offline;
    _emitSync();
  }

  void _emitSync() {
    if (!_syncController.isClosed) _syncController.add(currentSync);
  }

  void _publish(List<UserBook> books) {
    _books = List.unmodifiable(books);
    _controller.add(_books);
    _persist();
  }

  void _persist() {
    final cache = _cache;
    final userId = _currentUserId?.call();
    if (cache == null || userId == null) return;
    unawaited(
      cache.write(
        LibrarySnapshot(
          userId: userId,
          books: _books,
          pending: List.of(_pending),
        ),
      ),
    );
  }

  static bool _isConnectivity(Failure failure) =>
      failure.code == FailureCode.network ||
      failure.code == FailureCode.timeout;
}
