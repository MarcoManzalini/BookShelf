import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/book_quote.dart';
import '../mappers/book_quote_mapper.dart';

abstract interface class QuoteRemoteDataSource {
  Future<List<BookQuote>> fetchForBook(String userBookId);
  Future<BookQuote> insert(Map<String, dynamic> json);
  Future<BookQuote> update(String id, Map<String, dynamic> json);
  Future<void> delete(String id);
}

class SupabaseQuoteDataSource implements QuoteRemoteDataSource {
  SupabaseQuoteDataSource(this._client);

  final SupabaseClient _client;

  static const _table = 'book_quotes';

  @override
  Future<List<BookQuote>> fetchForBook(String userBookId) async {
    final rows = await _client
        .from(_table)
        .select()
        .eq('user_book_id', userBookId)
        .order('created_at', ascending: false);
    return rows.map(BookQuoteMapper.fromJson).toList();
  }

  @override
  Future<BookQuote> insert(Map<String, dynamic> json) async {
    final row = await _client.from(_table).insert(json).select().single();
    return BookQuoteMapper.fromJson(row);
  }

  @override
  Future<BookQuote> update(String id, Map<String, dynamic> json) async {
    final row =
        await _client.from(_table).update(json).eq('id', id).select().single();
    return BookQuoteMapper.fromJson(row);
  }

  @override
  Future<void> delete(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }
}
