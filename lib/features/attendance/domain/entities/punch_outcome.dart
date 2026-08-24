import 'package:equatable/equatable.dart';

import 'punch_receipt.dart';

/// The business rules the backend enforces on a punch (§5.2, plus the two
/// pre-flight refusals from §5.1 that the user can actually act on).
///
/// These are *not* errors in the transport sense — the request was understood
/// and definitively answered — so they travel as a successful [PunchOutcome]
/// rather than a `Failure`. Keeping them apart is what lets the UI switch
/// exhaustively on the rule instead of matching on message text, which §5
/// explicitly forbids.
enum AttendanceRule {
  /// 403 — fake GPS is on. The user has to turn it off.
  mockLocationDetected,

  /// 400 — the account has no employee record. Only HR can fix it.
  employeeNotFound,

  /// 409 — nobody assigned a shift. Only HR can fix it.
  noShiftAssigned,

  /// 409 — clock-in only; the last shift of the day has already ended.
  outsideShiftHours,

  /// 409 — clock-in only; the overnight shift is finished.
  overnightSessionDone,

  /// 409 — clock-in only; this session is already open. Clock out instead.
  sessionAlreadyStarted,

  /// 409 — clock-in only; this session already has both punches.
  sessionAlreadyCompleted,

  /// 409 — clock-out only; this session is already closed.
  sessionAlreadyCheckedOut,

  /// 409 — clock-out only; there is no matching clock-in.
  sessionNotStarted,

  /// 409 — clock-out only; the checkout window has closed.
  afterCheckoutWindow,

  /// 409 — clock-out only, and the one rule with a recovery path: collect a
  /// reason from the user and send the same punch again with `notes` set
  /// (§4 rule 4, §7 rule 6).
  earlyCheckoutRequiresReason;

  /// True when re-sending the punch with `notes` clears the refusal. Only
  /// [earlyCheckoutRequiresReason] is recoverable this way — every other rule
  /// needs a different time, a different day, or HR.
  bool get isResolvableWithReason => this == earlyCheckoutRequiresReason;
}

/// The `error.details` a refusal carries (§5.2).
///
/// Times arrive as opaque strings — the spec interpolates them straight into
/// user-facing copy without committing to a format — so they are kept as the
/// backend sent them and only normalised for display by [PunchBlockDetails]'s
/// consumers. §7 rule 7 requires showing these instead of generic copy.
class PunchBlockDetails extends Equatable {
  final String? sessionLabel;
  final int? sessionOrder;

  /// `EARLY_CHECKOUT_REQUIRES_REASON` — clocking out before this needs a
  /// reason.
  final String? earliestCheckout;

  /// `AFTER_CHECKOUT_WINDOW` — the last moment a clock-out was allowed.
  final String? latestCheckout;

  /// `SESSION_ALREADY_*` — when the next session opens.
  final String? nextSessionStart;

  /// `OUTSIDE_SHIFT_HOURS` — when the day's last shift ended.
  final String? lastShiftEnd;

  /// `OVERNIGHT_SESSION_DONE`.
  final String? endedAt;
  final String? nextStarts;

  /// `NO_SHIFT_ASSIGNED`.
  final String? employeeId;

  /// Everything the backend sent, so a detail added server-side is never
  /// silently dropped before it reaches a log.
  final Map<String, dynamic> raw;

  const PunchBlockDetails({
    this.sessionLabel,
    this.sessionOrder,
    this.earliestCheckout,
    this.latestCheckout,
    this.nextSessionStart,
    this.lastShiftEnd,
    this.endedAt,
    this.nextStarts,
    this.employeeId,
    this.raw = const {},
  });

  static const empty = PunchBlockDetails();

  @override
  List<Object?> get props => [
    sessionLabel,
    sessionOrder,
    earliestCheckout,
    latestCheckout,
    nextSessionStart,
    lastShiftEnd,
    endedAt,
    nextStarts,
    employeeId,
    raw,
  ];
}

/// The result of a punch the server answered definitively.
///
/// Transport, auth and server errors are *not* modelled here — they stay in
/// `Result.failure` — so a `Result<PunchOutcome>.success` means "the backend
/// gave a real answer", and this type says what that answer was.
sealed class PunchOutcome {
  const PunchOutcome();
}

/// The punch was written. Read [PunchReceipt.verification] before celebrating:
/// a stored punch may still have failed its location check.
class PunchRecorded extends PunchOutcome with EquatableMixin {
  final PunchReceipt receipt;

  const PunchRecorded(this.receipt);

  @override
  List<Object?> get props => [receipt];
}

/// The punch was refused by a rule the user (or HR) can respond to.
class PunchBlocked extends PunchOutcome with EquatableMixin {
  final AttendanceRule rule;

  /// The backend's wording, already tailored to the situation — preferred
  /// over any generic copy the app could invent (§5, §7 rule 7).
  final String message;

  final PunchBlockDetails details;

  const PunchBlocked({
    required this.rule,
    required this.message,
    this.details = PunchBlockDetails.empty,
  });

  @override
  List<Object?> get props => [rule, message, details];
}
