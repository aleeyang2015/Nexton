/// The business error codes the leave endpoints answer with
/// (leave-request-flutter.md §4), and the client-side tokens they map to.
///
/// Following `AttendanceRemoteDataSourceImpl`'s pattern: the datasource
/// branches on `error.code` (never the free-text message), and turns a
/// recognised code into a `Failure.validation(message: <token>)`. The token
/// is what `failure_localizer.dart` translates to UI copy — so the whole
/// leave feature shows the right message without `ValidationFailure` needing
/// an extra `code` field.
class LeaveErrorCode {
  LeaveErrorCode._();

  // Wire codes.
  static const String pendingRequestExists = 'PENDING_REQUEST_EXISTS';
  static const String overlappingLeave = 'OVERLAPPING_LEAVE';
  static const String insufficientBalance = 'INSUFFICIENT_BALANCE';
  static const String stepChanged = 'STEP_CHANGED';
  static const String notApprover = 'NOT_APPROVER';
  static const String invalidStatus = 'INVALID_STATUS';
  static const String employeeNotFound = 'EMPLOYEE_NOT_FOUND';

  // Client-side tokens (also used as [Failure.validation] messages, and looked
  // up in `_byValidationCode`).
  static const String tokenPendingRequestExists = 'leavePendingRequestExists';
  static const String tokenOverlappingLeave = 'leaveOverlapping';
  static const String tokenInsufficientBalance = 'leaveInsufficientBalance';
  static const String tokenStepChanged = 'leaveStepChanged';
  static const String tokenNotApprover = 'leaveNotApprover';
  static const String tokenInvalidStatus = 'leaveInvalidStatus';
  static const String tokenEmployeeNotFound = 'leaveEmployeeNotFound';

  static const Map<String, String> tokenByWire = {
    pendingRequestExists: tokenPendingRequestExists,
    overlappingLeave: tokenOverlappingLeave,
    insufficientBalance: tokenInsufficientBalance,
    stepChanged: tokenStepChanged,
    notApprover: tokenNotApprover,
    invalidStatus: tokenInvalidStatus,
    employeeNotFound: tokenEmployeeNotFound,
  };
}
