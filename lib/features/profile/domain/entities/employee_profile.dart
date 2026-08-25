import 'package:equatable/equatable.dart';

/// The signed-in user's Core HR employee record, as the rest of the app sees
/// it. Holds no JSON concerns — that belongs to [EmployeeProfileModel] in the
/// data layer.
///
/// Deliberately separate from `auth`'s `User`: that entity is the session's
/// identity and permissions, sourced from `/auth/me`. This is the employee
/// profile Core HR owns, sourced from `/core_hr/employees/me` — a different
/// endpoint, fetched independently so a slow or failing profile lookup can
/// never hold up sign-in.
class EmployeeProfile extends Equatable {
  final String id;
  final String fullName;
  final String? positionTitle;
  final String? departmentName;
  final String? email;
  final String? avatarUrl;

  const EmployeeProfile({
    required this.id,
    required this.fullName,
    this.positionTitle,
    this.departmentName,
    this.email,
    this.avatarUrl,
  });

  @override
  List<Object?> get props => [
    id,
    fullName,
    positionTitle,
    departmentName,
    email,
    avatarUrl,
  ];
}
