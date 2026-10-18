import '../../../../core/errors/error_mapper.dart';
import '../../domain/entities/shared_shelf.dart';
import '../../domain/entities/shelf_share.dart';
import '../../domain/repositories/shelf_share_repository.dart';
import '../datasources/shelf_share_remote_data_source.dart';
import '../mappers/shelf_share_mapper.dart';

class ShelfShareRepositoryImpl implements ShelfShareRepository {
  const ShelfShareRepositoryImpl(this._remote);

  final ShelfShareRemoteDataSource _remote;

  @override
  Future<ShelfShare?> shareFor(String shelfName) => _guard(() async {
        final row = await _remote.findByShelf(shelfName);
        return row == null ? null : ShelfShareMapper.shareFromJson(row);
      });

  @override
  Future<ShelfShare> create(String shelfName) => _guard(
        () async =>
            ShelfShareMapper.shareFromJson(await _remote.insert(shelfName)),
      );

  @override
  Future<void> revoke(String shelfName) =>
      _guard(() => _remote.deleteByShelf(shelfName));

  @override
  Future<SharedShelf?> fetchShared(String token) async {
    final trimmed = token.trim();
    if (trimmed.isEmpty) return null;
    return _guard(() async {
      final json = await _remote.getShared(trimmed);
      return json == null ? null : ShelfShareMapper.sharedFromJson(json);
    });
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      throw mapError(e);
    }
  }
}
