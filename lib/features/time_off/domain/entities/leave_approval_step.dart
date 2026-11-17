import 'package:equatable/equatable.dart';

/// The role an approval step belongs to (leave-request-flutter.md §2).
enum LeaveStepRole { deptHead, hr, unknown }

/// Where a single approval step stands (leave-request-flutter.md §2).
///
/// - `waiting` — an earlier step hasn't approved yet
/// - `pending` — this is the step awaiting a decision right now
/// - `approved` / `rejected` — decided
enum LeaveStepStatus { waiting, pending, approved, rejected }

/// One entry of `LeaveRequestResponse.steps[]` — the multi-step approval chain
/// the history/detail timeline renders.
class LeaveApprovalStep extends Equatable {
  final String? id;
  final int stepNo;
  final LeaveStepRole role;
  final String? approverName;

  /// The approver's employee id (`approver.id`): filled for a dept-head step
  /// from the start, for an HR step once decided. Null when not sent.
  final String? approverId;
  final LeaveStepStatus status;
  final String? note;

  /// When this step was approved or rejected, local time. Null for a step
  /// not decided yet.
  final DateTime? decidedAt;

  const LeaveApprovalStep({
    this.id,
    required this.stepNo,
    required this.role,
    this.approverName,
    this.approverId,
    required this.status,
    this.note,
    this.decidedAt,
  });

  /// True once this step has been approved or rejected.
  bool get isDecided =>
      status == LeaveStepStatus.approved || status == LeaveStepStatus.rejected;

  static LeaveStepRole roleFromWire(String? value) => switch (value) {
    'dept_head' => LeaveStepRole.deptHead,
    'hr' => LeaveStepRole.hr,
    _ => LeaveStepRole.unknown,
  };

  static LeaveStepStatus statusFromWire(String? value) => switch (value) {
    'pending' => LeaveStepStatus.pending,
    'approved' => LeaveStepStatus.approved,
    'rejected' => LeaveStepStatus.rejected,
    _ => LeaveStepStatus.waiting,
  };

  @override
  List<Object?> get props => [
    id,
    stepNo,
    role,
    approverName,
    approverId,
    status,
    note,
    decidedAt,
  ];
}
