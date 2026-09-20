import 'package:equatable/equatable.dart';

class Profile extends Equatable {
  const Profile({required this.id, this.displayName, this.avatarUrl});

  final String id;
  final String? displayName;
  final String? avatarUrl;

  Profile copyWith({String? displayName, String? avatarUrl}) => Profile(
        id: id,
        displayName: displayName ?? this.displayName,
        avatarUrl: avatarUrl ?? this.avatarUrl,
      );

  @override
  List<Object?> get props => [id, displayName, avatarUrl];
}
