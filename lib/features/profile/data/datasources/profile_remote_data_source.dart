import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/app_config.dart';
import '../../domain/entities/profile.dart';

class ProfileRemoteDataSource {
  ProfileRemoteDataSource(this._client);

  final SupabaseClient _client;

  static const _table = 'profiles';

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('No session', code: 'session_not_found');
    }
    return user.id;
  }

  Future<Profile> getProfile() async {
    final row =
        await _client.from(_table).select().eq('id', _userId).maybeSingle();
    if (row != null) return _fromRow(row);
    final created =
        await _client.from(_table).insert({'id': _userId}).select().single();
    return _fromRow(created);
  }

  Future<Profile> updateDisplayName(String displayName) async {
    final row = await _client
        .from(_table)
        .update({'display_name': displayName})
        .eq('id', _userId)
        .select()
        .single();
    return _fromRow(row);
  }

  /// [goal] null clears the yearly target.
  Future<Profile> updateReadingGoal(int? goal) async {
    final row = await _client
        .from(_table)
        .update({'reading_goal': goal})
        .eq('id', _userId)
        .select()
        .single();
    return _fromRow(row);
  }

  Future<Profile> uploadAvatar(Uint8List bytes, String extension) async {
    final ext = extension.toLowerCase().replaceAll('.', '');
    final path = '$_userId/${DateTime.now().millisecondsSinceEpoch}.$ext';
    final bucket = _client.storage.from(AppConfig.avatarsBucket);

    await bucket.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(
        contentType: ext == 'jpg' ? 'image/jpeg' : 'image/$ext',
      ),
    );
    final url = bucket.getPublicUrl(path);

    final row = await _client
        .from(_table)
        .update({'avatar_url': url})
        .eq('id', _userId)
        .select()
        .single();

    await _removeAvatarsExcept(path);
    return _fromRow(row);
  }

  Future<void> deleteAccount() async {
    await _removeAvatarsExcept(null);
    await _client.rpc<void>('delete_my_account');
    // The user no longer exists server-side, so only clear the local session.
    await _client.auth.signOut(scope: SignOutScope.local);
  }

  /// Best effort: stale avatars must never fail the main operation.
  Future<void> _removeAvatarsExcept(String? keepPath) async {
    try {
      final bucket = _client.storage.from(AppConfig.avatarsBucket);
      final files = await bucket.list(path: _userId);
      final stale = files
          .map((f) => '$_userId/${f.name}')
          .where((p) => p != keepPath)
          .toList();
      if (stale.isNotEmpty) await bucket.remove(stale);
    } catch (_) {}
  }

  static Profile _fromRow(Map<String, dynamic> row) => Profile(
        id: row['id'] as String,
        displayName: row['display_name'] as String?,
        avatarUrl: row['avatar_url'] as String?,
        readingGoal: (row['reading_goal'] as num?)?.toInt(),
      );
}
