/// The business error codes the OT endpoints answer with, and the
/// client-side tokens they become.
///
/// As `LeaveErrorCode`: the data source branches on `error.code` (never the
/// free-text message) and turns a known code into
/// `Failure.validation(message: <token>)`; `failure_localizer.dart` turns the
/// token into Lao or English. Every OT screen shows the same words.
///
/// Not mapped, on purpose:
/// * `EMPLOYEE_NOT_FOUND` keeps its code and gets #4's shared text;
/// * `NOT_FOUND` keeps its `404`, for the screen to go back and refresh;
/// * a `422` keeps its field, for the screen to put text under it;
/// * a code the App does not know keeps the server's message.
///
/// The approval codes are here too, so the head's calls (#48, #49) only add
/// calls.
class OtErrorCode {
  OtErrorCode._();

  /// `403` on cancel only: a waiting request is rejected, not cancelled.
  /// A generic code everywhere else, so it is not in [tokenByWire].
  static const String forbidden = 'FORBIDDEN';

  static const String tokenDisabled = 'otDisabled';
  static const String tokenNotEligible = 'otNotEligible';
  static const String tokenTooFarBack = 'otTooFarBack';
  static const String tokenOverlap = 'otOverlap';
  static const String tokenOverlapsShift = 'otOverlapsShift';
  static const String tokenEmployeeLeft = 'otEmployeeLeft';
  static const String tokenAlreadyDecided = 'otAlreadyDecided';
  static const String tokenAnnounced = 'otAnnounced';
  static const String tokenFull = 'otFull';
  static const String tokenJoinClosed = 'otJoinClosed';
  static const String tokenStepChanged = 'otStepChanged';
  static const String tokenStarted = 'otStarted';
  static const String tokenAlreadyPaid = 'otAlreadyPaid';
  static const String tokenPaidByHand = 'otPaidByHand';
  static const String tokenNotApprover = 'otNotApprover';
  static const String tokenCancelForbidden = 'otCancelForbidden';

  /// A reject with no reason (`422 errors.comment`, #49). Not a server code,
  /// so not in [allTokens].
  static const String tokenReasonRequired = 'apprReasonRequired';

  /// Wire code → token, for every OT call.
  static const Map<String, String> tokenByWire = {
    'OT_DISABLED': tokenDisabled,
    'OT_NOT_ELIGIBLE': tokenNotEligible,
    'OT_TOO_FAR_BACK': tokenTooFarBack,
    'OT_OVERLAP': tokenOverlap,
    'OT_OVERLAPS_SHIFT': tokenOverlapsShift,
    'OT_EMPLOYEE_LEFT': tokenEmployeeLeft,
    'OT_ALREADY_DECIDED': tokenAlreadyDecided,
    'OT_ANNOUNCED': tokenAnnounced,
    'OT_FULL': tokenFull,
    'OT_JOIN_CLOSED': tokenJoinClosed,
    'STEP_CHANGED': tokenStepChanged,
    'OT_STARTED': tokenStarted,
    'OT_ALREADY_PAID': tokenAlreadyPaid,
    'OT_PAID_BY_HAND': tokenPaidByHand,
    'NOT_APPROVER': tokenNotApprover,
  };

  /// Every token an OT call can raise.
  static const Set<String> allTokens = {
    tokenDisabled,
    tokenNotEligible,
    tokenTooFarBack,
    tokenOverlap,
    tokenOverlapsShift,
    tokenEmployeeLeft,
    tokenAlreadyDecided,
    tokenAnnounced,
    tokenFull,
    tokenJoinClosed,
    tokenStepChanged,
    tokenStarted,
    tokenAlreadyPaid,
    tokenPaidByHand,
    tokenNotApprover,
    tokenCancelForbidden,
  };
}
