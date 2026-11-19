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

  /// A date range in which every day is a company day off.
  allDaysOff,
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

  /// The years whose balance a request is charged to, earliest first: each
  /// leave day is charged to its own year, so a leave across the new year
  /// spends two balances. [now]'s year when no day is picked yet.
  ///
  /// While a range's days off are not known its days cannot be told apart by
  /// year, and nothing is checked: the year of its first day is given, for
  /// the card to show.
  static List<int> balanceYears(LeaveRequestFormState state, DateTime now) {
    final years = [...?state.daysByYear?.keys]..sort();
    if (years.isNotEmpty) return years;
    return [state.firstLeaveDate?.year ?? now.year];
  }

  /// The days the selected type has left in one year, from that year's
  /// [balances].
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

  /// The earliest year in which [state] asks for more days than [type] has
  /// left, or null when every year can pay for its own days.
  ///
  /// [remainingByYear] holds [remainingDays] for each year the request
  /// touches. A year that is missing or null is not known yet (still
  /// loading, or its load failed), and nothing is blocked on it.
  ///
  /// A new request is checked in every year it touches. An edit is checked
  /// in a year only when it asks for **more** days there than the request
  /// already had (`coveredDays`): the server does the same, so fixing the
  /// reason on a request made before the balance dropped is never refused.
  static int? shortYear({
    required LeaveRequestFormState state,
    required LeaveType? type,
    required Map<int, double?> remainingByYear,
  }) {
    if (type == null || type.allowNegativeBalance) return null;

    // Not known while the company's days off are not: the server counts.
    final asked = state.daysByYear;
    if (asked == null) return null;

    for (final year in asked.keys.toList()..sort()) {
      final remaining = remainingByYear[year];
      if (remaining == null) continue;

      final days = asked[year]!;
      if (days <= state.coveredDays(year)) continue;
      if (days > remaining) return year;
    }
    return null;
  }

  /// The years whose balance the form reads: those the request touches
  /// ([balanceYears]), and the year the server last named as short
  /// (`balanceRefusedYear`, #87) when the form could not tell that year by
  /// itself. Earliest first.
  static List<int> yearsToRead(LeaveRequestFormState state, DateTime now) {
    final years = balanceYears(state, now);
    final refused = state.balanceRefusedYear;
    if (refused == null || years.contains(refused)) return years;
    return [...years, refused]..sort();
  }

  /// The year whose balance the form's card shows: the one [shortYear] names,
  /// so the user sees which balance is short; else the year the server
  /// named when it refused what was sent (#87); else the first of [years]
  /// (from [balanceYears]).
  static int cardYear({
    required LeaveRequestFormState state,
    required LeaveType? type,
    required List<int> years,
    required Map<int, double?> remainingByYear,
  }) =>
      shortYear(state: state, type: type, remainingByYear: remainingByYear) ??
      state.balanceRefusedYear ??
      years.first;

  /// Why [state] cannot be sent, or null when it can.
  ///
  /// [remainingByYear] is as for [shortYear].
  static LeaveFormBlock? block({
    required LeaveRequestFormState state,
    required LeaveType? type,
    required Map<int, double?> remainingByYear,
  }) {
    // Independent of the leave type: the return-to-work date can't land on or
    // before the last leave day.
    if (!state.hasValidReturnToWorkDate) return LeaveFormBlock.returnDate;

    // Nothing to ask for, whatever the type: the server refuses a request
    // that comes to zero days.
    if (state.isAllDaysOff) return LeaveFormBlock.allDaysOff;

    if (type == null) return null;
    // The type needs a file, and none is attached yet.
    if (type.requiresAttachment && state.files.isEmpty) {
      return LeaveFormBlock.attachmentRequired;
    }

    // The count of a range is not known while the company's days off are not.
    // The form then checks nothing that depends on it: the server counts the
    // days and decides.
    final total = state.totalDays;
    if (total == null) return null;

    final max = type.maxDaysPerRequest;
    if (max != null && total > max) return LeaveFormBlock.maxDays;

    final short = shortYear(
      state: state,
      type: type,
      remainingByYear: remainingByYear,
    );
    return short == null ? null : LeaveFormBlock.insufficientBalance;
  }
}
