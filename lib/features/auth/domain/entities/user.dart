import 'package:equatable/equatable.dart';

/// A signed-in user, as the rest of the app sees it.
/// Holds no JSON concerns — that belongs to UserModel in the data layer.
class User extends Equatable {
  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final String? jobTitle;

  const User({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    this.jobTitle,
  });

  @override
  List<Object?> get props => [id, email, displayName, avatarUrl, jobTitle];
}
