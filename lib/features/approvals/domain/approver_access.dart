import 'package:equatable/equatable.dart';

import '../../attendance/domain/entities/attendance_approval_request.dart';
import '../../attendance/domain/entities/time_correction_status.dart';
import '../../auth/domain/entities/user.dart';
import '../../overtime/domain/entities/ot_request.dart';
import '../../overtime/domain/entities/ot_step.dart';
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

  /// Whether a request owned by [ownerId], opened on the employee's own
  /// page (from a push, #53), belongs on the approver's page instead: it is
  /// someone else's, and [user] may open the approver's page
  /// ([attendance]: the off-site and "forgot to scan" one). An unknown
  /// owner or user keeps the page where it is; the server decides the rest.
  static bool opensAsApprover({
    required String? ownerId,
    required User? user,
    bool attendance = false,
  }) {
    final own = user?.employeeId;
    if (ownerId == null || ownerId.isEmpty || own == null || own.isEmpty) {
      return false;
    }
    if (ownerId == own) return false;
    final access = ApproverAccess.of(user);
    return access.canSeeApprovals &&
        (!attendance || access.canApproveAttendance);
  }

  /// Whether [user] gets Approve and Reject on [request]: it is pending
  /// with a step waiting, it is not their own, they approved no other step
  /// of it, and the waiting step is theirs. An HR step is HR's (the
  /// leave permission, or an admin role; a plain head is refused there with
  /// `NOT_APPROVER`); a dept-head step is the approver named on it.
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
    // Already approved a step: never another one too. One person decides
    // at most one step of a request; the server answers a second one with
    // `403 NOT_APPROVER` (#19, 16 Nov 2026), e.g. a head who also holds the
    // HR right, on the HR step after approving the head step. Any approved
    // step counts, as for OT: the waiting one is never approved, and a
    // `step_no` the server left off is read as 0 for every step.
    final approvedOne = request.steps.any(
      (s) => s.status == LeaveStepStatus.approved && s.approverId == employeeId,
    );
    if (approvedOne) return false;
    final access = ApproverAccess.of(user);
    return switch (step.role) {
      LeaveStepRole.hr => access.isAdmin || access.canManageLeave,
      LeaveStepRole.deptHead => step.approverId == employeeId,
      LeaveStepRole.unknown => false,
    };
  }

  /// Whether [user] gets Approve and Reject on the attendance [request], an
  /// off-site scan (#46) or a "forgot to scan" (#47): it is pending with a step waiting, it is not their own, and the
  /// waiting step is theirs. An HR step is HR's (the attendance permission,
  /// or an admin role); a dept-head or `specific` step is the employee named
  /// on it.
  ///
  /// Only hides buttons that would fail: the server still decides, and its
  /// refusal is shown.
  static bool canDecideAttendance(
    AttendanceApprovalRequest request,
    User? user,
  ) {
    final employeeId = user?.employeeId;
    if (user == null || employeeId == null || employeeId.isEmpty) {
      return false;
    }
    final step = request.currentStep;
    if (request.status != TimeCorrectionStatus.pending || step == null) {
      return false;
    }
    if (isOwnAttendance(request, employeeId)) return false;
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

  /// Whether a head gets Approve and Reject on the OT [request] (#49): it is
  /// pending, the step waiting now is a dept-head or `specific` one naming
  /// them, it is not their own, and they have not approved an earlier step
  /// (the server refuses that with `NOT_APPROVER`). HR rights add nothing
  /// (the App does not decide OT's HR steps).
  static bool canDecideOt(OtRequest request, User? user) {
    final employeeId = user?.employeeId;
    if (employeeId == null || employeeId.isEmpty) return false;
    if (request.status != OtStatus.pending) return false;
    if (request.employeeId == employeeId) return false;
    final step = request.pendingStep;
    if (step == null || step.role == OtStepRole.hr) return false;
    final approvedEarlier = request.steps.any(
      (s) => s.approverId == employeeId && s.status == OtStepStatus.approved,
    );
    if (approvedEarlier) return false;
    return step.approverId == employeeId;
  }

  /// Whether a head may cancel the approved OT [request] (#49): it is
  /// approved, they approved one of its head steps (an HR step approved on
  /// the web adds nothing), and it has not started ([now] before
  /// `starts_at`, both moments). After that only HR can.
  static bool canCancelApprovedOt(OtRequest request, User? user, DateTime now) {
    final employeeId = user?.employeeId;
    if (employeeId == null || employeeId.isEmpty) return false;
    if (request.status != OtStatus.approved) return false;
    final startsAt = request.startsAt;
    if (startsAt == null || !now.isBefore(startsAt)) return false;
    return request.steps.any(
      (s) =>
          s.approverId == employeeId &&
          s.status == OtStepStatus.approved &&
          s.role != OtStepRole.hr,
    );
  }

  /// Whether [request] is the signed-in employee's own: it shows a line in
  /// place of buttons, and a `NOT_APPROVER` on it says "your own".
  static bool isOwnAttendance(
    AttendanceApprovalRequest request,
    String? employeeId,
  ) =>
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
