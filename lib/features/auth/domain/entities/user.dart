import 'package:equatable/equatable.dart';

/// A signed-in user, as the rest of the app sees it.
/// Holds no JSON concerns — that belongs to UserModel in the data layer.
///
/// Shape follows `GET /auth/me` (see auth.md): `roles`, `permissions` and
/// `modules` are **plural arrays lifted from the JWT claims**, so they only
/// change after a refresh or a re-login — never mid-session.
class User extends Equatable {
  final String id;
  final String tenantId;
  final String email;
  final String firstName;
  final String lastName;
  final List<String> roles;
  final List<String> permissions;
  final List<String> modules;

  /// Core HR employee row. Nullable, and **not** the same identifier as [id] —
  /// employee-scoped calls must key on this, not on the user id.
  final String? employeeId;

  /// ⚠ `/auth/me` never returns the three fields below; they live on the Core
  /// HR employee record. They stay null until that endpoint is wired up.
  final String? profilePhotoUrl;
  final String? departmentName;
  final String? positionTitle;

  const User({
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
  });

  /// Full name for display, falling back to the email when the profile has no
  /// name yet.
  String get displayName {
    final name = '$firstName $lastName'.trim();
    return name.isEmpty ? email : name;
  }

  bool hasRole(String role) => roles.contains(role);

  bool hasPermission(String permission) => permissions.contains(permission);

  bool hasModule(String module) => modules.contains(module);

  @override
  List<Object?> get props => [
    id,
    tenantId,
    email,
    firstName,
    lastName,
    roles,
    permissions,
    modules,
    employeeId,
    profilePhotoUrl,
    departmentName,
    positionTitle,
  ];
}
