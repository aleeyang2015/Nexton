import '../../domain/entities/leave_approval_step.dart';
import 'leave_parse.dart';

/// Reads one entry of `LeaveRequestResponse.steps[]`
/// (leave-request-flutter.md §3.6).
class LeaveRequestStepModel {
  const LeaveRequestStepModel._();

  static LeaveApprovalStep fromJson(Map<String, dynamic> json) {
    final approver = json['approver'];
    final status = LeaveApprovalStep.statusFromWire(
      LeaveJson.str(json['status']),
    );
    final decided =
        status == LeaveStepStatus.approved ||
        status == LeaveStepStatus.rejected;

    return LeaveApprovalStep(
      id: LeaveJson.nonEmpty(json['id']),
      stepNo: LeaveJson.intOf(json['step_no']) ?? 0,
      role: LeaveApprovalStep.roleFromWire(LeaveJson.str(json['step_role'])),
      approverName: approver is Map
          ? LeaveJson.nonEmpty(approver['name'])
          : null,
      status: status,
      note: LeaveJson.nonEmpty(json['note']),
      // `updated_at` is set to the decision time when a step is approved or
      // rejected. On a step not decided yet it is only when the row was
      // last touched, and is not shown as a decision.
      decidedAt: decided ? LeaveJson.dateTime(json['updated_at']) : null,
    );
  }
}
