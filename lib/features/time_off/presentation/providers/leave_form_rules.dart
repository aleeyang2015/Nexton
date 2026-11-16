import '../../domain/entities/leave_balance.dart';
import '../../domain/entities/leave_type.dart';
import 'leave_request_form_state.dart';

/// Why the request-leave form will not send, in the order the reasons are
/// checked.
enum LeaveFormBlock {
  /// The return-to-work date is on or before the last leave day.
  returnDate,

  /// The leave type needs a supporting document.
  attachmentRequired,

  /// More days than the leave type allows in one request.
  maxDays,

  /// More days than the balance holds.
  insufficientBalance,
}

/// The form's own checks, as pure functions: the widget asks, and shows the
/// answer. They mirror what the server will do with the request, so the user
/// learns before sending instead of after; they are not a second copy of the
/// backend's rules, and the server still has the last word.
class LeaveFormRules {
  LeaveFormRules._();

  /// The types the form, the picker and the history filter offer: the ones HR
  /// has switched on, in the server's order.
  ///
  /// [keepId] stays in the list even when switched off: the type of a request
  /// being edited, so its owner can still fix a typo in the reason, or the
  /// type a filter is already set to.
  static List<LeaveType> offered(List<LeaveType> types, {String? keepId}) => [
    for (final type in types)
      if (type.isActive || type.id == keepId) type,
  ];

  /// The year whose balance a request is charged to: the year of its first
  /// leave day, or [now]'s when no day is picked yet.
  ///
  /// A leave that runs across the new year is checked against that first year
  /// only, which is what the server charges today (Nexton-Backend#193 will
  /// split it; this check changes with it).
  static int balanceYear(LeaveRequestFormState state, DateTime now) =>
      state.firstLeaveDate?.year ?? now.year;

  /// The days the selected type has left in the year being checked.
  ///
  /// Null while the year's balances have not loaded, when nothing is known
  /// yet. Once they have, a type with no row for that year has **0** left:
  /// the server counts a missing row as nothing to spend.
  static double? remainingDays(List<LeaveBalance>? balances, String? typeId) {
    if (balances == null || typeId == null) return null;
    for (final balance in balances) {
      if (balance.leaveTypeId == typeId) return balance.remainingDays;
    }
    return 0;
  }

  /// Why [state] cannot be sent, or null when it can.
  ///
  /// [remaining] is from [remainingDays]; null means the balance is not known
  /// yet, and nothing is blocked on it.
  static LeaveFormBlock? block({
    required LeaveRequestFormState state,
    required LeaveType? type,
    required double? remaining,
  }) {
    // Independent of the leave type: the return-to-work date can't land on or
    // before the last leave day.
    if (!state.hasValidReturnToWorkDate) return LeaveFormBlock.returnDate;

    if (type == null) return null;
    if (type.requiresAttachment) return LeaveFormBlock.attachmentRequired;

    final max = type.maxDaysPerRequest;
    if (max != null && state.totalDays > max) return LeaveFormBlock.maxDays;

    if (remaining != null &&
        !type.allowNegativeBalance &&
        _exceedsBalance(state, remaining)) {
      return LeaveFormBlock.insufficientBalance;
    }
    return null;
  }

  /// A new request is checked against what is left. An edit is checked only
  /// when it asks for **more** days than the request already had: the server
  /// does the same, so fixing the reason on a request made before the balance
  /// dropped is never refused.
  ///
  /// That holds only while the edit still draws on the balance the request
  /// already drew on. Moved to another leave type, or to days in another
  /// year, it is spending a balance it never had days in, and is checked like
  /// a new request.
  static bool _exceedsBalance(LeaveRequestFormState state, double remaining) {
    final original = state.originalTotalDays;
    if (state.editsSameBalance &&
        original != null &&
        state.totalDays <= original) {
      return false;
    }
    return state.totalDays > remaining;
  }
}
