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

  /// Who asked for the leave (`employee.id`). Null when the server sent
  /// none. Compared with the signed-in user's own employee id to tell an
  /// approver's own request from someone else's.
  final String? employeeId;
  final String employeeName;
  final String? employeeNumber;
  final String? departmentName;

  /// The employee's department id (`employee.department.id`): "My team"
  /// keeps an HR-head's rows to the departments they head (#50).
  final String? departmentId;
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
    this.employeeId,
    required this.employeeName,
    this.employeeNumber,
    this.departmentName,
    this.departmentId,
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

  /// What the cancel endpoint accepts by status alone: pending or approved.
  /// Whether the App offers it also depends on the date; see
  /// [canCancelInApp].
  bool get canCancel =>
      status == LeaveStatus.pending || status == LeaveStatus.approved;

  /// The first day the request is charged for: the first of its
  /// `request_days`, which is what the server goes by. A Saturday-to-Tuesday
  /// range at a company closed at the weekend starts on Monday. Falls back
  /// to [startDate] for a request that lists no days.
  DateTime get firstLeaveDay {
    final first = requestDays.isEmpty
        ? startDate
        : requestDays.reduce((a, b) => a.isBefore(b) ? a : b);
    return DateTime(first.year, first.month, first.day);
  }

  /// True for an approved leave that is on or past its first leave day on
  /// [today]. The owner can no longer cancel it; HR handles it.
  bool hasStartedOn(DateTime today) =>
      status == LeaveStatus.approved &&
      !DateTime(today.year, today.month, today.day).isBefore(firstLeaveDay);

  /// Whether the owner may cancel this request in the App on [today]: a
  /// pending request on any date, an approved one only before its first
  /// leave day.
  ///
  /// [today] is the phone's date; the server goes by the company's. When
  /// the two differ around midnight the server's `LEAVE_ALREADY_STARTED`
  /// decides.
  bool canCancelInApp(DateTime today) => switch (status) {
    LeaveStatus.pending => true,
    LeaveStatus.approved => !hasStartedOn(today),
    _ => false,
  };

  /// The step awaiting a decision right now, if any.
  LeaveApprovalStep? get currentStep {
    for (final step in steps) {
      if (step.status == LeaveStepStatus.pending) return step;
    }
    return null;
  }

  /// The last step that has already approved, if any — who cleared this
  /// request before it reached the step now pending.
  ///
  /// The chain runs dept head (or team lead) first, HR last, so a non-null
  /// answer on a pending request means it is past its first approval.
  LeaveApprovalStep? get lastApprovedStep {
    LeaveApprovalStep? latest;
    for (final step in steps) {
      if (step.status != LeaveStepStatus.approved) continue;
      if (latest == null || step.stepNo > latest.stepNo) latest = step;
    }
    return latest;
  }

  /// True while nobody in the chain has approved yet — the request is still
  /// sitting with its first approver.
  bool get awaitsFirstApproval => lastApprovedStep == null;

  /// True when the step now pending is the last one in the chain, so
  /// approving it grants the leave outright rather than passing it on.
  ///
  /// A request whose chain never arrived (empty [steps]) is not treated as
  /// final: the safe reading of "no chain" is "we don't know yet", and the
  /// plain approve wording says nothing that could turn out to be wrong.
  bool get isFinalApprovalStep {
    final current = currentStep;
    if (current == null) return false;

    for (final step in steps) {
      if (step.stepNo > current.stepNo) return false;
    }
    return true;
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
    employeeId,
    employeeName,
    employeeNumber,
    departmentName,
    departmentId,
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
