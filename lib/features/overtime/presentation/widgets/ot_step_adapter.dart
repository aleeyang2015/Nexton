import '../../../time_off/domain/entities/leave_approval_step.dart';
import '../../../time_off/domain/entities/leave_status.dart';
import '../../domain/entities/ot_request.dart';
import '../../domain/entities/ot_step.dart';

/// Lets the leave timeline (`LeaveApprovalTimeline`, #17) draw an OT
/// request's steps: the same roles, statuses, names, notes and decision
/// times, so the two read alike.
class OtStepAdapter {
  OtStepAdapter._();

  static LeaveApprovalStep toLeaveStep(OtStep step) => LeaveApprovalStep(
    id: step.id,
    stepNo: step.stepNo,
    role: switch (step.role) {
      OtStepRole.deptHead => LeaveStepRole.deptHead,
      OtStepRole.hr => LeaveStepRole.hr,
      OtStepRole.unknown => LeaveStepRole.unknown,
    },
    // A status the App does not know is drawn as not reached, never as
    // decided.
    status: switch (step.status) {
      OtStepStatus.pending => LeaveStepStatus.pending,
      OtStepStatus.approved => LeaveStepStatus.approved,
      OtStepStatus.rejected => LeaveStepStatus.rejected,
      OtStepStatus.waiting || OtStepStatus.unknown => LeaveStepStatus.waiting,
    },
    approverName: step.approverName,
    note: step.note,
    decidedAt: step.actedAt,
  );

  /// The request's status, for the timeline's cancelled end; null for one
  /// the App does not know (the steps are drawn as they are).
  static LeaveStatus? toLeaveStatus(OtStatus status) => switch (status) {
    OtStatus.pending => LeaveStatus.pending,
    OtStatus.approved => LeaveStatus.approved,
    OtStatus.rejected => LeaveStatus.rejected,
    OtStatus.cancelled => LeaveStatus.cancelled,
    OtStatus.unknown => null,
  };
}
