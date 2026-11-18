import 'time_correction_detail.dart';
import 'time_correction_status.dart';

/// What an approver decides on, whichever kind of attendance request it is
/// (#46 off-site scans, #47 "forgot to scan"): whose it is, where it stands,
/// and its approval steps. One rule ([ApproverAccess.canDecideAttendance])
/// and one decision flow serve both.
abstract interface class AttendanceApprovalRequest {
  String get id;
  TimeCorrectionEmployee get employee;
  TimeCorrectionStatus get status;
  List<TimeCorrectionApprovalStep> get steps;

  /// The step awaiting a decision right now, if any.
  TimeCorrectionApprovalStep? get currentStep;
}
