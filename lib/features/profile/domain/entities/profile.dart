import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

class Profile extends Equatable {
  const Profile({
    required this.id,
    this.displayName,
    this.avatarUrl,
    this.readingGoal,
  });

  final String id;
  final String? displayName;
  final String? avatarUrl;

  /// Books the reader wants to finish each year, if they set a target.
  final int? readingGoal;

  Profile copyWith({
    String? displayName,
    String? avatarUrl,
    ValueGetter<int?>? readingGoal,
  }) =>
      Profile(
        id: id,
        displayName: displayName ?? this.displayName,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        readingGoal: readingGoal != null ? readingGoal() : this.readingGoal,
      );

  @override
  List<Object?> get props => [id, displayName, avatarUrl, readingGoal];
}
