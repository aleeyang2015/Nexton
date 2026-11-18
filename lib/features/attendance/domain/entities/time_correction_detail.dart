import 'package:equatable/equatable.dart';

import '../../../time_off/domain/entities/leave_approval_step.dart';
import 'attendance_approval_request.dart';
import 'attendance_day.dart';
import 'time_correction_status.dart';
import 'time_correction_type.dart';

/// One time-correction request in full, as
/// `GET /attendance/correction-requests/:id` returns it — the detail page.
///
/// Times of day are offsets from midnight, as on [TimeCorrectionRequest].
class TimeCorrectionDetail extends Equatable
    implements AttendanceApprovalRequest {
  @override
  final String id;
  @override
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
  @override
  final TimeCorrectionStatus status;

  /// The step now awaiting a decision; 0 once none is.
  final int currentStepNo;
  @override
  final List<TimeCorrectionApprovalStep> steps;
  final DateTime submittedAt;

  /// The day as it stands once the request was approved
  /// (`attendance_record`, #45); null until then.
  final TimeCorrectionResult? result;

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
    this.result,
  });

  /// The same request with [status]: a withdrawal the server accepted, shown
  /// before the request could be read again.
  TimeCorrectionDetail withStatus(TimeCorrectionStatus status) =>
      TimeCorrectionDetail(
        id: id,
        employee: employee,
        requestDate: requestDate,
        type: type,
        clockIn: clockIn,
        clockOut: clockOut,
        shift: shift,
        reason: reason,
        attachmentUrl: attachmentUrl,
        status: status,
        currentStepNo: 0,
        steps: steps,
        submittedAt: submittedAt,
        result: result,
      );

  /// Only an undecided request can be withdrawn.
  bool get canCancel => status == TimeCorrectionStatus.pending;

  /// Whether the login with [ownEmployeeId] may withdraw it: pending, and
  /// not someone else's. Without an id on either side the server decides
  /// (it refuses anyone else's with `CANNOT_CANCEL`), so the button stays:
  /// the employee's own list must never lose it for a field the answer
  /// leaves out.
  bool canCancelBy(String? ownEmployeeId) {
    if (!canCancel) return false;
    final owner = employee.id;
    if (owner == null || ownEmployeeId == null || ownEmployeeId.isEmpty) {
      return true;
    }
    return owner == ownEmployeeId;
  }

  /// The step awaiting a decision right now, if any — its id goes with an
  /// approve/reject call as `step_id`, so the backend can refuse a decision
  /// aimed at a step someone else has already moved past (§4.7).
  @override
  TimeCorrectionApprovalStep? get currentStep {
    for (final step in steps) {
      if (step.status == LeaveStepStatus.pending) return step;
    }
    return null;
  }

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
    result,
  ];
}

/// The corrected day, as `attendance_record` holds it once HR approved the
/// request: the times are the company's wall clock, read as written.
///
/// [clockIn] and [clockOut] are the corrected part's (`session`) when the
/// answer names it, else the day's first clock-in and last clock-out.
class TimeCorrectionResult extends Equatable {
  final DateTime? date;
  final DateTime? clockIn;
  final DateTime? clockOut;

  /// The day's status as the backend rolls it up (`present`, `late`, ...).
  final String? status;
  final double? workHours;
  final bool isLate;
  final int? lateMinutes;

  const TimeCorrectionResult({
    this.date,
    this.clockIn,
    this.clockOut,
    this.status,
    this.workHours,
    this.isLate = false,
    this.lateMinutes,
  });

  /// The same figures as a history day, so the status pill is #10's own.
  AttendanceDay get asDay => AttendanceDay(
    date: date,
    status: status,
    totalWorkHours: workHours,
    sessions: [
      AttendanceSession(
        clockIn: clockIn,
        clockOut: clockOut,
        isLate: isLate,
        lateMinutes: lateMinutes,
      ),
    ],
  );

  @override
  List<Object?> get props => [
    date,
    clockIn,
    clockOut,
    status,
    workHours,
    isLate,
    lateMinutes,
  ];
}

class TimeCorrectionEmployee extends Equatable {
  /// The employee record's id, when the answer carries one.
  final String? id;
  final String name;
  final String? employeeNumber;
  final String? departmentName;
  final String? departmentNameLo;

  const TimeCorrectionEmployee({
    this.id,
    required this.name,
    this.employeeNumber,
    this.departmentName,
    this.departmentNameLo,
  });

  @override
  List<Object?> get props => [
    id,
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
  /// The step's own id, sent back as `step_id` on a decision.
  final String? id;

  final int stepNo;
  final LeaveStepRole role;

  /// The employee record named on the step (`approver.id`); a dept-head or
  /// `specific` step is theirs to decide (#46). Null on an HR step.
  final String? approverId;
  final String? approverName;
  final LeaveStepStatus status;
  final String? note;

  /// When the step was opened, and when its approver decided.
  final DateTime? createdAt;
  final DateTime? actedAt;

  const TimeCorrectionApprovalStep({
    this.id,
    required this.stepNo,
    required this.role,
    required this.status,
    this.approverId,
    this.approverName,
    this.note,
    this.createdAt,
    this.actedAt,
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
    createdAt,
    actedAt,
  ];
}
