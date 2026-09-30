import '../../../time_off/data/datasources/leave_error_code.dart';

/// The business error codes an approver's decision on a time-correction
/// request can come back with (attendance-correction-requests.md §6), and
/// the client-side tokens `failure_localizer.dart` translates.
///
/// Corrections run the *same* approval workflow as leave — the step roles and
/// statuses are already the shared `LeaveStepRole` / `LeaveStepStatus` enums —
/// so the refusals a decision can hit are the same refusals, and they reuse
/// the copy that already exists for them rather than duplicating it.
class TimeCorrectionErrorCode {
  TimeCorrectionErrorCode._();

  // Wire codes (§6).
  static const String stepChanged = 'STEP_CHANGED';
  static const String notApprover = 'NOT_APPROVER';
  static const String notPending = 'NOT_PENDING';
  static const String employeeNotFound = 'EMPLOYEE_NOT_FOUND';

  static const Map<String, String> tokenByWire = {
    stepChanged: LeaveErrorCode.tokenStepChanged,
    notApprover: LeaveErrorCode.tokenNotApprover,
    // "…is no longer pending" — the same thing as leave's INVALID_STATUS.
    notPending: LeaveErrorCode.tokenInvalidStatus,
    employeeNotFound: LeaveErrorCode.tokenEmployeeNotFound,
  };
}
