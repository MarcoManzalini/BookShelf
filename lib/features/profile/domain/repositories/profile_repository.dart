import 'dart:typed_data';

import '../entities/profile.dart';

abstract interface class ProfileRepository {
  /// All methods throw [Failure] on error.
  Future<Profile> getProfile();

  Future<Profile> updateDisplayName(String displayName);

  /// Sets (or with null, clears) the books-per-year goal.
  Future<Profile> updateReadingGoal(int? goal);

  Future<Profile> uploadAvatar(Uint8List bytes, String extension);

  /// Calls the `delete_my_account` RPC, then clears the local session.
  Future<void> deleteAccount();
}
