import 'package:equatable/equatable.dart';

import 'personal_info.dart';
import 'shift_detail.dart';

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

  /// The assigned shift's own name (`shift.name`/`shift.name_lo`) — e.g.
  /// "Regular Shift" — shown on the attendance card in place of a generic
  /// "on time" badge. Null when the employee has no shift assigned yet.
  final String? shiftName;
  final String? shiftNameLo;

  /// The assigned shift's segments (`shift.shift_details[]`) — e.g. the
  /// morning and afternoon halves of a split day — in the order the backend
  /// sends them. Empty when the employee has no shift assigned yet.
  final List<ShiftDetail> shiftDetails;

  /// Whether this employee may ask for OT (`can_ask_ot`): the company's OT
  /// is on, their own OT switch is on, and the login is linked to them.
  /// Null when the server did not say (an older server): the App then
  /// offers Ask, and the server's refusal explains.
  final bool? canAskOt;

  /// The read-only personal page's record (#58).
  final EmployeePersonalInfo personal;

  const EmployeeProfile({
    required this.id,
    required this.fullName,
    this.positionTitle,
    this.departmentName,
    this.email,
    this.avatarUrl,
    this.shiftName,
    this.shiftNameLo,
    this.shiftDetails = const [],
    this.canAskOt,
    this.personal = const EmployeePersonalInfo(),
  });

  /// This profile with the photo at [url] (#59: the photo just changed).
  EmployeeProfile withAvatar(String url) => EmployeeProfile(
    id: id,
    fullName: fullName,
    positionTitle: positionTitle,
    departmentName: departmentName,
    email: email,
    avatarUrl: url,
    shiftName: shiftName,
    shiftNameLo: shiftNameLo,
    shiftDetails: shiftDetails,
    canAskOt: canAskOt,
    personal: personal,
  );

  @override
  List<Object?> get props => [
    id,
    fullName,
    positionTitle,
    departmentName,
    email,
    avatarUrl,
    shiftName,
    shiftNameLo,
    shiftDetails,
    canAskOt,
    personal,
  ];
}
