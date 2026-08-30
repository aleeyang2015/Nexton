import '../../domain/entities/leave_approval_step.dart';
import 'leave_parse.dart';

/// Reads one entry of `LeaveRequestResponse.steps[]`
/// (leave-request-flutter.md §3.6).
class LeaveRequestStepModel {
  const LeaveRequestStepModel._();

  static LeaveApprovalStep fromJson(Map<String, dynamic> json) {
    final approver = json['approver'];
    return LeaveApprovalStep(
      id: LeaveJson.nonEmpty(json['id']),
      stepNo: LeaveJson.intOf(json['step_no']) ?? 0,
      role: LeaveApprovalStep.roleFromWire(LeaveJson.str(json['step_role'])),
      approverName: approver is Map
          ? LeaveJson.nonEmpty(approver['name'])
          : null,
      status: LeaveApprovalStep.statusFromWire(LeaveJson.str(json['status'])),
      note: LeaveJson.nonEmpty(json['note']),
    );
  }
}
