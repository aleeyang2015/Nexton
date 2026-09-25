import 'package:equatable/equatable.dart';

import '../../../time_off/domain/entities/leave_approval_step.dart';
import 'time_correction_status.dart';
import 'time_correction_type.dart';

/// One time-correction request in full, as
/// `GET /attendance/correction-requests/:id` returns it — the detail page.
///
/// Times of day are offsets from midnight, as on [TimeCorrectionRequest].
class TimeCorrectionDetail extends Equatable {
  final String id;
  final TimeCorrectionEmployee employee;

  /// The day being corrected.
  final DateTime requestDate;
  final TimeCorrectionType type;
  final Duration? clockIn;
  final Duration? clockOut;
  final TimeCorrectionShift? shift;
  final String reason;

  /// The evidence file's URL, or null when none was attached.
  final String? attachmentUrl;
  final TimeCorrectionStatus status;

  /// The step now awaiting a decision; 0 once none is.
  final int currentStepNo;
  final List<TimeCorrectionApprovalStep> steps;
  final DateTime submittedAt;

  const TimeCorrectionDetail({
    required this.id,
    required this.employee,
    required this.requestDate,
    required this.type,
    required this.clockIn,
    required this.clockOut,
    required this.shift,
    required this.reason,
    required this.attachmentUrl,
    required this.status,
    required this.currentStepNo,
    required this.steps,
    required this.submittedAt,
  });

  /// Only an undecided request can be withdrawn.
  bool get canCancel => status == TimeCorrectionStatus.pending;

  /// Time between the requested clock-in and clock-out, when both are set.
  Duration? get requestedDuration {
    final start = type.needsClockIn ? clockIn : null;
    final end = type.needsClockOut ? clockOut : null;
    if (start == null || end == null || end <= start) return null;
    return end - start;
  }

  @override
  List<Object?> get props => [
    id,
    employee,
    requestDate,
    type,
    clockIn,
    clockOut,
    shift,
    reason,
    attachmentUrl,
    status,
    currentStepNo,
    steps,
    submittedAt,
  ];
}

class TimeCorrectionEmployee extends Equatable {
  final String name;
  final String? employeeNumber;
  final String? departmentName;
  final String? departmentNameLo;

  const TimeCorrectionEmployee({
    required this.name,
    this.employeeNumber,
    this.departmentName,
    this.departmentNameLo,
  });

  @override
  List<Object?> get props => [
    name,
    employeeNumber,
    departmentName,
    departmentNameLo,
  ];
}

/// The shift segment the correction was filed against (`shift_detail`),
/// with the shift it belongs to (`shift_detail.shift`).
class TimeCorrectionShift extends Equatable {
  final String? name;
  final String? nameLo;
  final Duration? start;
  final Duration? end;
  final int? breakMinutes;
  final bool overtimeEligible;
  final String? shiftName;
  final String? shiftNameLo;
  final String? shiftCode;

  const TimeCorrectionShift({
    this.name,
    this.nameLo,
    this.start,
    this.end,
    this.breakMinutes,
    this.overtimeEligible = false,
    this.shiftName,
    this.shiftNameLo,
    this.shiftCode,
  });

  @override
  List<Object?> get props => [
    name,
    nameLo,
    start,
    end,
    breakMinutes,
    overtimeEligible,
    shiftName,
    shiftNameLo,
    shiftCode,
  ];
}

/// One entry of `steps[]`. Roles and statuses follow the same approval
/// workflow as leave requests, so their enums are shared.
class TimeCorrectionApprovalStep extends Equatable {
  final int stepNo;
  final LeaveStepRole role;
  final String? approverName;
  final LeaveStepStatus status;
  final String? note;

  /// When the step was opened, and when its approver decided.
  final DateTime? createdAt;
  final DateTime? actedAt;

  const TimeCorrectionApprovalStep({
    required this.stepNo,
    required this.role,
    required this.status,
    this.approverName,
    this.note,
    this.createdAt,
    this.actedAt,
  });

  @override
  List<Object?> get props => [
    stepNo,
    role,
    approverName,
    status,
    note,
    createdAt,
    actedAt,
  ];
}
