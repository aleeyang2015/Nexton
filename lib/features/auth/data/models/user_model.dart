import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/user.dart';

part 'user_model.g.dart';

/// Wire format for [User]. Only this layer knows about JSON keys.
@JsonSerializable()
class UserModel {
  final String id;
  final String email;

  @JsonKey(name: 'display_name')
  final String displayName;

  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;

  @JsonKey(name: 'job_title')
  final String? jobTitle;

  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    this.jobTitle,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  /// Map to the domain entity the rest of the app consumes
  User toEntity() => User(
        id: id,
        email: email,
        displayName: displayName,
        avatarUrl: avatarUrl,
        jobTitle: jobTitle,
      );
}
