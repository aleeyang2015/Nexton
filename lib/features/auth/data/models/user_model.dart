import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/user.dart';

part 'user_model.g.dart';

/// Wire format for [User] — the exact map `GET /auth/me` returns.
/// Only this layer knows about JSON keys.
///
/// Two keys on the wire are deliberately not modelled: `user_id`, which is a
/// duplicate of `id`, and nothing else. The three profile fields below are
/// modelled but never sent by `/auth/me`; they exist so a future Core HR
/// employee lookup can fill them in without changing the entity.
@JsonSerializable()
class UserModel {
  final String id;

  @JsonKey(name: 'tenant_id', defaultValue: '')
  final String tenantId;

  @JsonKey(defaultValue: '')
  final String email;

  @JsonKey(name: 'first_name', defaultValue: '')
  final String firstName;

  @JsonKey(name: 'last_name', defaultValue: '')
  final String lastName;

  @JsonKey(defaultValue: <String>[])
  final List<String> roles;

  @JsonKey(defaultValue: <String>[])
  final List<String> permissions;

  @JsonKey(defaultValue: <String>[])
  final List<String> modules;

  /// Nullable on the wire, and back-filled by the backend from
  /// `employees.work_email` when the users row has none.
  @JsonKey(name: 'employee_id')
  final String? employeeId;

  @JsonKey(name: 'profile_photo_url')
  final String? profilePhotoUrl;

  @JsonKey(name: 'department_name')
  final String? departmentName;

  @JsonKey(name: 'position_title')
  final String? positionTitle;

  /// Whether the user heads a department (`is_department_head`, live on
  /// `/auth/me` since 14 Nov, read fresh on every call). Null when the
  /// server did not say (an older server); the login answer then counts.
  /// Read so that a value of another type is "not said", never a failed
  /// sign-in.
  @JsonKey(name: 'is_department_head', fromJson: _boolOrNull)
  final bool? isDepartmentHead;

  static bool? _boolOrNull(Object? value) => value is bool ? value : null;

  const UserModel({
    required this.id,
    required this.tenantId,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.roles = const [],
    this.permissions = const [],
    this.modules = const [],
    this.employeeId,
    this.profilePhotoUrl,
    this.departmentName,
    this.positionTitle,
    this.isDepartmentHead,
  });

  /// This user, with [isDepartmentHead] filled in when the server did not
  /// say it.
  UserModel withDepartmentHead(bool? value) => isDepartmentHead != null
      ? this
      : UserModel(
          id: id,
          tenantId: tenantId,
          email: email,
          firstName: firstName,
          lastName: lastName,
          roles: roles,
          permissions: permissions,
          modules: modules,
          employeeId: employeeId,
          profilePhotoUrl: profilePhotoUrl,
          departmentName: departmentName,
          positionTitle: positionTitle,
          isDepartmentHead: value,
        );

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  /// Map to the domain entity the rest of the app consumes
  User toEntity() => User(
    id: id,
    tenantId: tenantId,
    email: email,
    firstName: firstName,
    lastName: lastName,
    roles: roles,
    permissions: permissions,
    modules: modules,
    employeeId: employeeId,
    profilePhotoUrl: profilePhotoUrl,
    departmentName: departmentName,
    positionTitle: positionTitle,
    isDepartmentHead: isDepartmentHead ?? false,
  );
}
