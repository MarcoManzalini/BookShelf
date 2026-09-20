import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../search/domain/entities/book.dart';
import '../../domain/entities/reading_status.dart';
import '../../domain/entities/user_book.dart';
import '../mappers/user_book_mapper.dart';

abstract interface class LibraryRemoteDataSource {
  Future<List<UserBook>> fetchAll();
  Future<UserBook?> fetchById(String id);
  Future<UserBook> insert(Book book, ReadingStatus status);
  Future<UserBook> update(UserBook book);
  Future<void> delete(String id);
}

class SupabaseLibraryDataSource implements LibraryRemoteDataSource {
  SupabaseLibraryDataSource(this._client);

  final SupabaseClient _client;

  static const _table = 'user_books';

  @override
  Future<List<UserBook>> fetchAll() async {
    final rows = await _client
        .from(_table)
        .select()
        .order('created_at', ascending: false);
    return rows.map(UserBookMapper.fromJson).toList();
  }

  @override
  Future<UserBook?> fetchById(String id) async {
    final row = await _client.from(_table).select().eq('id', id).maybeSingle();
    return row == null ? null : UserBookMapper.fromJson(row);
  }

  @override
  Future<UserBook> insert(Book book, ReadingStatus status) async {
    final json = UserBookMapper.toInsertJson(book, status);
    if (status != ReadingStatus.wantToRead) {
      json['started_at'] = _today();
    }
    if (status == ReadingStatus.read) {
      json['finished_at'] = _today();
      json['current_page'] = book.pageCount ?? 0;
    }
    final row = await _client.from(_table).insert(json).select().single();
    return UserBookMapper.fromJson(row);
  }

  @override
  Future<UserBook> update(UserBook book) async {
    final row = await _client
        .from(_table)
        .update(UserBookMapper.toUpdateJson(book))
        .eq('id', book.id)
        .select()
        .single();
    return UserBookMapper.fromJson(row);
  }

  @override
  Future<void> delete(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }

  static String _today() => DateTime.now().toIso8601String().substring(0, 10);
}
