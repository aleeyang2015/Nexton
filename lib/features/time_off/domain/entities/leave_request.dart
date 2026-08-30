import 'package:equatable/equatable.dart';

import 'leave_approval_step.dart';
import 'leave_attachment.dart';
import 'leave_duration_type.dart';
import 'leave_status.dart';
import 'leave_type.dart';

/// One leave request as `LeaveRequestResponse` (leave-request-flutter.md §3.6).
///
/// The same shape is returned by the employee's `GET /leave/requests/my`, the
/// detail endpoint, and the approver's `GET /leave/requests/my-approvals`, so
/// the history tab, the detail page and the approvals tab all render from this.
class LeaveRequest extends Equatable {
  final String id;
  final String employeeName;
  final String? employeeNumber;
  final String? departmentName;
  final LeaveType leaveType;
  final DateTime startDate;
  final DateTime endDate;

  /// Every individual day the request covers (`request_days[]`).
  final List<DateTime> requestDays;
  final DateTime? returnDate;
  final double totalDays;
  final LeaveDurationType durationType;
  final String reason;
  final LeaveStatus status;

  /// 1-based index of the step awaiting a decision, or null when the request
  /// is no longer pending.
  final int? currentStepNo;
  final List<LeaveApprovalStep> steps;
  final List<LeaveAttachment> attachments;
  final DateTime? createdAt;

  const LeaveRequest({
    required this.id,
    required this.employeeName,
    this.employeeNumber,
    this.departmentName,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    this.requestDays = const [],
    this.returnDate,
    required this.totalDays,
    this.durationType = LeaveDurationType.fullDay,
    this.reason = '',
    required this.status,
    this.currentStepNo,
    this.steps = const [],
    this.attachments = const [],
    this.createdAt,
  });

  bool get isPending => status == LeaveStatus.pending;

  /// Editable only while still pending (leave-request-flutter.md §3.4).
  bool get canEdit => status == LeaveStatus.pending;

  /// Cancellable while pending or already approved (§3.5).
  bool get canCancel =>
      status == LeaveStatus.pending || status == LeaveStatus.approved;

  /// The step awaiting a decision right now, if any.
  LeaveApprovalStep? get currentStep {
    for (final step in steps) {
      if (step.status == LeaveStepStatus.pending) return step;
    }
    return null;
  }

  /// The reviewer's note on a rejection, surfaced on the history card.
  String? get rejectionNote {
    for (final step in steps) {
      if (step.status == LeaveStepStatus.rejected &&
          (step.note ?? '').isNotEmpty) {
        return step.note;
      }
    }
    return null;
  }

  @override
  List<Object?> get props => [
    id,
    employeeName,
    employeeNumber,
    departmentName,
    leaveType,
    startDate,
    endDate,
    requestDays,
    returnDate,
    totalDays,
    durationType,
    reason,
    status,
    currentStepNo,
    steps,
    attachments,
    createdAt,
  ];
}
