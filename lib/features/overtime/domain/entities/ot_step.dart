import 'package:equatable/equatable.dart';

/// Who decides a step. OT builds only these two (`ot_settings.go`).
enum OtStepRole { deptHead, hr, unknown }

/// Where one approval step stands.
///
/// - `waiting`: an earlier step has not approved yet;
/// - `pending`: this step is the one waiting for a decision now;
/// - `approved` / `rejected`: decided.
enum OtStepStatus { waiting, pending, approved, rejected, unknown }

/// One step of an OT request's approval chain (`steps[]`).
class OtStep extends Equatable {
  final String id;
  final int stepNo;
  final OtStepRole role;

  /// Who is to decide, or decided. Null before an approver is set.
  final String? approverId;
  final String? approverName;

  final OtStepStatus status;
  final String? note;

  /// When the step was decided, on the phone's clock. Null until then.
  final DateTime? actedAt;
  final DateTime? createdAt;

  const OtStep({
    required this.id,
    required this.stepNo,
    required this.role,
    this.approverId,
    this.approverName,
    required this.status,
    this.note,
    this.actedAt,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    stepNo,
    role,
    approverId,
    approverName,
    status,
    note,
    actedAt,
    createdAt,
  ];
}
