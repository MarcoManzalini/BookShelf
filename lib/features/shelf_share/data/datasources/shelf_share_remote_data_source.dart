import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class ShelfShareRemoteDataSource {
  Future<Map<String, dynamic>?> findByShelf(String shelfName);
  Future<Map<String, dynamic>> insert(String shelfName);
  Future<void> deleteByShelf(String shelfName);

  /// Payload of `get_shared_shelf`, null for an unknown token.
  Future<Map<String, dynamic>?> getShared(String token);
}

class SupabaseShelfShareDataSource implements ShelfShareRemoteDataSource {
  SupabaseShelfShareDataSource(this._client);

  final SupabaseClient _client;

  static const _table = 'shelf_shares';
  static const _columns = 'id, shelf_name, token';

  /// Rows whose shelf is [shelfName], compared case-insensitively as in the
  /// unique index. Done in Dart: PostgREST pattern filters would treat `*`,
  /// `%` and `_` in a shelf name as wildcards.
  static List<Map<String, dynamic>> matching(
    List<Map<String, dynamic>> rows,
    String shelfName,
  ) {
    final wanted = shelfName.toLowerCase();
    return [
      for (final row in rows)
        if ((row['shelf_name'] as String).toLowerCase() == wanted) row,
    ];
  }

  /// The user's own shares (RLS), a handful of rows at most.
  Future<List<Map<String, dynamic>>> _rowsFor(String shelfName) async =>
      matching(await _client.from(_table).select(_columns), shelfName);

  @override
  Future<Map<String, dynamic>?> findByShelf(String shelfName) async =>
      (await _rowsFor(shelfName)).firstOrNull;

  @override
  Future<Map<String, dynamic>> insert(String shelfName) => _client
      .from(_table)
      .insert({'shelf_name': shelfName})
      .select(_columns)
      .single();

  @override
  Future<void> deleteByShelf(String shelfName) async {
    final ids = [for (final row in await _rowsFor(shelfName)) row['id']];
    if (ids.isEmpty) return;
    await _client.from(_table).delete().inFilter('id', ids);
  }

  @override
  Future<Map<String, dynamic>?> getShared(String token) async {
    final result = await _client.rpc<dynamic>(
      'get_shared_shelf',
      params: {'p_token': token},
    );
    return result is Map<String, dynamic> ? result : null;
  }
}
