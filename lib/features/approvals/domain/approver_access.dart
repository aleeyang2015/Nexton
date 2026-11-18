import 'package:equatable/equatable.dart';

import '../../attendance/domain/entities/offsite_detail.dart';
import '../../attendance/domain/entities/time_correction_status.dart';
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

  /// Whether [user] gets Approve and Reject on the off-site scan [request]
  /// (#46): it is pending with a step waiting, it is not their own, and the
  /// waiting step is theirs. An HR step is HR's (the attendance permission,
  /// or an admin role); a dept-head or `specific` step is the employee named
  /// on it.
  ///
  /// Only hides buttons that would fail: the server still decides, and its
  /// refusal is shown.
  static bool canDecideOffsite(OffsiteRequestDetail request, User? user) {
    final employeeId = user?.employeeId;
    if (user == null || employeeId == null || employeeId.isEmpty) {
      return false;
    }
    final step = request.currentStep;
    if (request.status != TimeCorrectionStatus.pending || step == null) {
      return false;
    }
    if (isOwnOffsite(request, employeeId)) return false;
    // Already approved an earlier step: never the next one too (the server
    // leaves such a request out of "waiting on me", and refuses it).
    final approvedEarlier = request.steps.any(
      (s) =>
          s.stepNo < step.stepNo &&
          s.status == LeaveStepStatus.approved &&
          s.approverId == employeeId,
    );
    if (approvedEarlier) return false;
    final access = ApproverAccess.of(user);
    final named = step.approverId;
    return switch (step.role) {
      LeaveStepRole.hr => access.isAdmin || access.canManageAttendance,
      // `dept_head`, and `specific` (read as unknown): the named employee.
      // A step that names no one yet (the guide: `approver` may be null
      // until acted) is left to the server, whose refusal hides the buttons.
      LeaveStepRole.deptHead || LeaveStepRole.unknown =>
        named == null || named == employeeId,
    };
  }

  /// Whether [request] is the signed-in employee's own: it shows a line in
  /// place of buttons, and a `NOT_APPROVER` on it says "your own".
  static bool isOwnOffsite(OffsiteRequestDetail request, String? employeeId) =>
      employeeId != null &&
      employeeId.isNotEmpty &&
      request.employee.id == employeeId;

  @override
  List<Object?> get props => [
    isHead,
    isAdmin,
    hasStaffRecord,
    canManageLeave,
    canManageAttendance,
  ];
}
