import '../../../time_off/data/datasources/leave_error_code.dart';

/// What an approver's decision on an attendance request can be refused with
/// (#46 off-site scans, #47 "forgot to scan": the same codes from the same
/// workflow), as tokens `failure_localizer.dart` says in plain words. One
/// table for both; off-site adds the two refusals only a check-out raises
/// (`OffsiteErrorCode.decisionTokenByWire`).
class ApprovalDecisionCode {
  ApprovalDecisionCode._();

  // Wire codes.
  static const String notPending = 'NOT_PENDING';
  static const String stepChanged = 'STEP_CHANGED';
  static const String notApprover = 'NOT_APPROVER';
  static const String employeeNotFound = 'EMPLOYEE_NOT_FOUND';
  static const String tooEarlyCheckin = 'TOO_EARLY_CHECKIN';

  /// Someone already decided it (`NOT_PENDING`): the row goes and the lists
  /// are read again.
  static const String tokenAlreadyDecided = 'apprAlreadyDecided';

  /// `NOT_APPROVER`: another approver must decide this step. The decision
  /// notifier turns it into [tokenCannotDecideOwn] on the caller's own.
  static const String tokenAnotherApprover = 'apprAnotherApprover';

  /// `NOT_APPROVER` on the caller's own request.
  static const String tokenCannotDecideOwn = 'apprCannotDecideOwn';

  /// The final approval writes the punch, and the session rule can still
  /// turn it down: the request stays waiting, so the row stays.
  static const String tokenTooEarlyCheckin = 'offsiteTooEarlyCheckin';

  /// Wire code → client token, for approve and reject.
  static const Map<String, String> tokenByWire = {
    notPending: tokenAlreadyDecided,
    stepChanged: LeaveErrorCode.tokenStepChanged,
    notApprover: tokenAnotherApprover,
    employeeNotFound: LeaveErrorCode.tokenEmployeeNotFound,
    tooEarlyCheckin: tokenTooEarlyCheckin,
  };

  /// The refusals that mean the request moved on without this approver: it
  /// leaves their waiting list, and the lists and page are read again. Each
  /// kind's own "gone" (404) token counts too.
  static const Set<String> staleTokens = {
    tokenAlreadyDecided,
    LeaveErrorCode.tokenStepChanged,
  };
}
