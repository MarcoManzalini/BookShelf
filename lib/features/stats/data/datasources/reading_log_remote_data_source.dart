import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/reading_log.dart';
import '../mappers/reading_log_mapper.dart';

abstract interface class ReadingLogRemoteDataSource {
  Future<ReadingLog> insert(Map<String, dynamic> json);
  Future<List<ReadingLog>> fetchForBook(String userBookId);
  Future<List<ReadingLog>> fetchAll({DateTime? since});
}

class SupabaseReadingLogDataSource implements ReadingLogRemoteDataSource {
  SupabaseReadingLogDataSource(this._client);

  final SupabaseClient _client;

  static const _table = 'reading_logs';

  @override
  Future<ReadingLog> insert(Map<String, dynamic> json) async {
    final row = await _client.from(_table).insert(json).select().single();
    return ReadingLogMapper.fromJson(row);
  }

  @override
  Future<List<ReadingLog>> fetchForBook(String userBookId) async {
    final rows = await _client
        .from(_table)
        .select()
        .eq('user_book_id', userBookId)
        .order('logged_on', ascending: false)
        .order('created_at', ascending: false);
    return rows.map(ReadingLogMapper.fromJson).toList();
  }

  @override
  Future<List<ReadingLog>> fetchAll({DateTime? since}) async {
    var query = _client.from(_table).select();
    if (since != null) {
      query = query.gte('logged_on', ReadingLogMapper.formatDate(since));
    }
    final rows = await query.order('logged_on', ascending: false);
    return rows.map(ReadingLogMapper.fromJson).toList();
  }
}
