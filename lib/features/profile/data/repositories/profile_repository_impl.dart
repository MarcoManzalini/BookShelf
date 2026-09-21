import 'dart:typed_data';

import '../../../../core/errors/error_mapper.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._remote);

  final ProfileRemoteDataSource _remote;

  @override
  Future<Profile> getProfile() => _guard(_remote.getProfile);

  @override
  Future<Profile> updateDisplayName(String displayName) =>
      _guard(() => _remote.updateDisplayName(displayName));

  @override
  Future<Profile> updateReadingGoal(int? goal) =>
      _guard(() => _remote.updateReadingGoal(goal));

  @override
  Future<Profile> uploadAvatar(Uint8List bytes, String extension) =>
      _guard(() => _remote.uploadAvatar(bytes, extension));

  @override
  Future<void> deleteAccount() => _guard(_remote.deleteAccount);

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      throw mapError(e);
    }
  }
}
