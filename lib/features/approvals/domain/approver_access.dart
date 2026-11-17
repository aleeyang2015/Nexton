import 'package:equatable/equatable.dart';

import '../../auth/domain/entities/user.dart';
import '../../time_off/domain/entities/leave_approval_step.dart';
import '../../time_off/domain/entities/leave_request.dart';

/// Who may see the Approvals place, and which of its sections: department
/// heads and HR only (owner's decision 8). Plain Dart, no Flutter.
///
/// HR is known by permission. The server treats the roles in [adminRoles]
/// as holding every permission (`platform/auth/claims.go`), while
/// `User.hasPermission` checks only the list, so they are checked here too.
///
/// An approver named on a `specific` step who is neither head nor HR does
/// not get the place: they decide on the web (decision 8). So does an HR
/// login with no staff record.
class ApproverAccess extends Equatable {
  const ApproverAccess._({
    required this.isHead,
    required this.isAdmin,
    required this.hasStaffRecord,
    required this.canManageLeave,
    required this.canManageAttendance,
  });

  factory ApproverAccess.of(User? user) {
    if (user == null) return none;
    final employeeId = user.employeeId;
    return ApproverAccess._(
      isHead: user.isDepartmentHead,
      isAdmin: user.roles.any(adminRoles.contains),
      hasStaffRecord: employeeId != null && employeeId.isNotEmpty,
      canManageLeave: user.hasPermission(leaveManagePermission),
      canManageAttendance: user.hasPermission(attendanceManagePermission),
    );
  }

  /// No one signed in.
  static const none = ApproverAccess._(
    isHead: false,
    isAdmin: false,
    hasStaffRecord: false,
    canManageLeave: false,
    canManageAttendance: false,
  );

  /// Roles the server gives every permission.
  static const adminRoles = {'admin', 'super_admin', 'superadmin'};

  /// HR's leave permission (`leave/handler.go`).
  static const leaveManagePermission = 'corehr:leaveRequest:manage';

  /// HR's off-site and "forgot to scan" permission
  /// (`attendance/correction_handler.go`).
  static const attendanceManagePermission = 'corehr:attendanceRecord:manage';

  final bool isHead;
  final bool isAdmin;
  final bool hasStaffRecord;
  final bool canManageLeave;
  final bool canManageAttendance;

  bool get canApproveLeave => isHead || isAdmin || canManageLeave;

  /// Off-site scans and "forgot to scan".
  bool get canApproveAttendance => isHead || isAdmin || canManageAttendance;

  /// OT's HR steps are not in the App: heads only.
  bool get canApproveOt => isHead;

  /// Decision 20: heads only.
  bool get canSeeTeam => isHead;

  bool get canSeeApprovals =>
      hasStaffRecord &&
      (canApproveLeave || canApproveAttendance || canApproveOt || canSeeTeam);

  /// Whether [user] gets Approve and Reject on [request]: it is pending
  /// with a step waiting, it is not their own, and the waiting step is
  /// theirs. An HR step is HR's (the leave permission, or an admin role; a
  /// plain head is refused there with `NOT_APPROVER`); a dept-head step is
  /// the approver named on it.
  ///
  /// Only hides buttons that would fail: the server still decides, and its
  /// refusal is shown.
  static bool canDecideLeave(LeaveRequest request, User? user) {
    final employeeId = user?.employeeId;
    if (user == null || employeeId == null || employeeId.isEmpty) {
      return false;
    }
    final step = request.currentStep;
    if (!request.isPending || step == null) return false;
    if (request.employeeId == employeeId) return false;
    final access = ApproverAccess.of(user);
    return switch (step.role) {
      LeaveStepRole.hr => access.isAdmin || access.canManageLeave,
      LeaveStepRole.deptHead => step.approverId == employeeId,
      LeaveStepRole.unknown => false,
    };
  }

  @override
  List<Object?> get props => [
    isHead,
    isAdmin,
    hasStaffRecord,
    canManageLeave,
    canManageAttendance,
  ];
}
