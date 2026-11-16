import '../../../../core/errors/failure.dart';

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

  /// `409` — the request's days changed under the caller (HR edited it).
  static const String leaveChanged = 'LEAVE_CHANGED';

  /// `404` on a call about one request (edit, cancel, approve, reject): the
  /// request is gone, or is not the caller's to see. It is a general code,
  /// so it is not in [tokenByWire]: creating a request can answer it about
  /// something else (a leave type), and that is not "the request is gone".
  static const String notFound = 'NOT_FOUND';

  // Client-side tokens (also used as [Failure.validation] messages, and looked
  // up in `_byValidationCode`).
  static const String tokenPendingRequestExists = 'leavePendingRequestExists';
  static const String tokenOverlappingLeave = 'leaveOverlapping';
  static const String tokenInsufficientBalance = 'leaveInsufficientBalance';
  static const String tokenStepChanged = 'leaveStepChanged';
  static const String tokenNotApprover = 'leaveNotApprover';
  static const String tokenInvalidStatus = 'leaveInvalidStatus';
  static const String tokenEmployeeNotFound = 'leaveEmployeeNotFound';
  static const String tokenLeaveChanged = 'leaveChanged';
  static const String tokenRequestGone = 'leaveRequestGone';

  static const Map<String, String> tokenByWire = {
    pendingRequestExists: tokenPendingRequestExists,
    overlappingLeave: tokenOverlappingLeave,
    insufficientBalance: tokenInsufficientBalance,
    stepChanged: tokenStepChanged,
    notApprover: tokenNotApprover,
    invalidStatus: tokenInvalidStatus,
    employeeNotFound: tokenEmployeeNotFound,
    leaveChanged: tokenLeaveChanged,
  };

  /// The leave token [failure] carries, or null when it carries none.
  static String? tokenOf(Failure failure) => failure.maybeWhen(
    validation: (message, _, _) =>
        _allTokens.contains(message) ? message : null,
    orElse: () => null,
  );

  static const Set<String> _allTokens = {
    tokenPendingRequestExists,
    tokenOverlappingLeave,
    tokenInsufficientBalance,
    tokenStepChanged,
    tokenNotApprover,
    tokenInvalidStatus,
    tokenEmployeeNotFound,
    tokenLeaveChanged,
    tokenRequestGone,
  };

  /// Refusals of an approve or a reject that mean the approver was looking
  /// at something that is no longer so: the lists are reloaded.
  static const Set<String> staleForApprover = {
    tokenStepChanged,
    tokenLeaveChanged,
    tokenInvalidStatus,
    tokenNotApprover,
    tokenRequestGone,
  };

  /// Refusals of an edit or a cancel that mean the owner's copy of the
  /// request is out of date: the history is reloaded and the page closes.
  static const Set<String> staleForOwner = {
    tokenLeaveChanged,
    tokenInvalidStatus,
    tokenRequestGone,
  };

  static bool isStaleForApprover(Failure failure) =>
      staleForApprover.contains(tokenOf(failure));

  static bool isStaleForOwner(Failure failure) =>
      staleForOwner.contains(tokenOf(failure));
}
