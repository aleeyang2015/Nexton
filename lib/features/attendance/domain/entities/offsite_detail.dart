import 'package:equatable/equatable.dart';

import '../../../time_off/domain/entities/leave_approval_step.dart';
import 'offsite_method.dart';
import 'time_correction_detail.dart';
import 'time_correction_status.dart';

/// One off-site scan request in full, as `GET /attendance/offsite-requests/:id`
/// and the two list endpoints return it (§3's `OffsiteRequestResponse`, §10).
///
/// Three of §10's objects are the ones the time-correction workflow already
/// models, field for field, so they are reused rather than re-declared:
/// [TimeCorrectionEmployee] for `employee`, [TimeCorrectionShift] for
/// `shift_detail`, and [TimeCorrectionApprovalStep] for `steps[]` — whose roles
/// and statuses are in turn leave's shared enums. The same goes for [status]:
/// §10's four values are [TimeCorrectionStatus]'s four values, with the same
/// wire literals.
class OffsiteRequestDetail extends Equatable {
  final String id;
  final TimeCorrectionEmployee employee;

  /// Which punch the scan stands in for.
  final OffsiteMethod method;

  /// Where the employee was standing. Nullable — §11.4 warns these can come
  /// back null.
  final double? latitude;
  final double? longitude;

  /// When the server stamped the scan: tenant-local wall clock, held unshifted.
  final DateTime? scanTimestamp;

  /// The working day the scan belongs to.
  final DateTime? scanDate;

  final int sessionOrder;

  /// The shift segment the scan landed in; null when the day has no shift.
  final TimeCorrectionShift? shift;

  /// The photo's URL. §3 makes it required, but a request stored before that
  /// rule, or one whose upload record is incomplete, can still arrive without.
  final String? attachmentUrl;

  final String reason;
  final TimeCorrectionStatus status;

  /// The step now awaiting a decision; 0 once none is.
  final int currentStepNo;

  /// Set once the punch exists — on final approval, or straight away for an
  /// employee with `can_work_offsite`.
  final String? attendanceRecordId;

  final List<TimeCorrectionApprovalStep> steps;
  final DateTime submittedAt;

  const OffsiteRequestDetail({
    required this.id,
    required this.employee,
    required this.method,
    required this.latitude,
    required this.longitude,
    required this.scanTimestamp,
    required this.scanDate,
    required this.sessionOrder,
    required this.shift,
    required this.attachmentUrl,
    required this.reason,
    required this.status,
    required this.currentStepNo,
    required this.attendanceRecordId,
    required this.steps,
    required this.submittedAt,
  });

  bool get hasCoordinates => latitude != null && longitude != null;

  /// Only an undecided request can be withdrawn by its owner (§9).
  bool get canCancel => status == TimeCorrectionStatus.pending;

  /// The step awaiting a decision right now, if any — its id goes with an
  /// approve/reject call as `step_id`, so the backend can refuse a decision
  /// aimed at a step someone else has already moved past (§7).
  TimeCorrectionApprovalStep? get currentStep {
    for (final step in steps) {
      if (step.status == LeaveStepStatus.pending) return step;
    }
    return null;
  }

  @override
  List<Object?> get props => [
    id,
    employee,
    method,
    latitude,
    longitude,
    scanTimestamp,
    scanDate,
    sessionOrder,
    shift,
    attachmentUrl,
    reason,
    status,
    currentStepNo,
    attendanceRecordId,
    steps,
    submittedAt,
  ];
}
