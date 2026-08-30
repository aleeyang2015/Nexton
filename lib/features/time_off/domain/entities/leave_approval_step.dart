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
  final LeaveStepStatus status;
  final String? note;

  const LeaveApprovalStep({
    this.id,
    required this.stepNo,
    required this.role,
    this.approverName,
    required this.status,
    this.note,
  });

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
  List<Object?> get props => [id, stepNo, role, approverName, status, note];
}
