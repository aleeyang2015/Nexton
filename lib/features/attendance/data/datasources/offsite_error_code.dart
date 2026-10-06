import '../../../time_off/data/datasources/leave_error_code.dart';
import '../../domain/entities/punch_outcome.dart';
import 'time_correction_error_code.dart';

/// The business refusals `POST /attendance/offsite-requests` can answer with
/// (attendance-offsite-requests.md §3), as the rules the app already knows.
///
/// §3 is explicit that the off-site scan is gated by the *same* session rules
/// as a normal clock-in/out, so eight of these codes are the punch endpoints'
/// own and map to the punch vocabulary — and therefore to the copy that
/// already exists for them. Only `OFFSITE_REQUEST_EXISTS` and
/// `TOO_EARLY_CHECKIN` are new here.
///
/// Deliberately *not* merged into `AttendanceRemoteDataSourceImpl._rules`: a
/// punch can't raise the two off-site refusals, and keeping the tables apart is
/// what stops a punch from ever reporting a rule its endpoint never sends.
class OffsiteErrorCode {
  OffsiteErrorCode._();

  /// Off-site only — a request for this session and direction is already in
  /// flight.
  static const String requestExists = 'OFFSITE_REQUEST_EXISTS';

  /// Off-site only — the clock-in window hasn't opened yet.
  static const String tooEarlyCheckin = 'TOO_EARLY_CHECKIN';

  /// The account has no employee record (§3 answers this as a 400).
  static const String employeeNotFound = 'EMPLOYEE_NOT_FOUND';

  /// Off-site only — the request isn't the caller's, or isn't pending any more
  /// (§9). The single refusal a withdrawal can hit.
  static const String cannotCancel = 'CANNOT_CANCEL';

  /// A decision's own refusals (§7, §8) are the ones the correction workflow
  /// already has copy for — `STEP_CHANGED`, `NOT_APPROVER`, `NOT_PENDING`,
  /// `EMPLOYEE_NOT_FOUND` — so [TimeCorrectionErrorCode.tokenByWire] covers
  /// them. This is the one refusal they don't share: the final approval writes
  /// the punch, and the session guard can still turn that down (the backend
  /// rolls the approval back when it does).
  static const String tokenTooEarlyCheckin = 'offsiteTooEarlyCheckin';

  /// `CANNOT_CANCEL` has no counterpart in the correction workflow — that one
  /// withdraws from a detail page that has already re-read the request — so it
  /// gets a token of its own.
  static const String tokenCannotCancel = 'offsiteCannotCancel';

  /// Wire code → client token, for the approve/reject calls.
  static const Map<String, String> decisionTokenByWire = {
    ...TimeCorrectionErrorCode.tokenByWire,
    tooEarlyCheckin: tokenTooEarlyCheckin,
  };

  /// Wire code → client token, for the cancel call.
  ///
  /// Kept apart from [decisionTokenByWire] for the reason that table is kept
  /// apart from the punch rules: §9 can answer with exactly two of these, and a
  /// withdrawal must never report `NOT_APPROVER` or `STEP_CHANGED` — refusals
  /// its endpoint cannot send.
  static const Map<String, String> cancelTokenByWire = {
    cannotCancel: tokenCannotCancel,
    employeeNotFound: LeaveErrorCode.tokenEmployeeNotFound,
  };

  static const Map<String, AttendanceRule> ruleByWire = {
    requestExists: AttendanceRule.offsiteRequestExists,
    tooEarlyCheckin: AttendanceRule.tooEarlyCheckin,
    employeeNotFound: AttendanceRule.employeeNotFound,
    'OUTSIDE_SHIFT_HOURS': AttendanceRule.outsideShiftHours,
    'OVERNIGHT_SESSION_DONE': AttendanceRule.overnightSessionDone,
    'SESSION_ALREADY_STARTED': AttendanceRule.sessionAlreadyStarted,
    'SESSION_ALREADY_CHECKED_OUT': AttendanceRule.sessionAlreadyCheckedOut,
    'SESSION_ALREADY_COMPLETED': AttendanceRule.sessionAlreadyCompleted,
    'SESSION_NOT_STARTED': AttendanceRule.sessionNotStarted,
    'AFTER_CHECKOUT_WINDOW': AttendanceRule.afterCheckoutWindow,
  };
}
