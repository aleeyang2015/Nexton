import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/attendance_day.dart';
import '../../domain/entities/punch_outcome.dart';
import '../../domain/entities/punch_receipt.dart';

/// Turns attendance domain values into the words the card and its dialogs
/// show. Pure functions, no widgets — the mapping is testable on its own and
/// the widgets stay small.
///
/// The governing rule comes from §5: the backend's `message` is already
/// tailored to the situation ("the next session starts at 13:30"), so it is
/// preferred wherever it exists. The localized strings here are the fallback
/// for when it doesn't — never a replacement for it.
class AttendanceCopy {
  AttendanceCopy._();

  /// What to tell the user about a refused punch.
  static String rule(AppLocalizations l10n, PunchBlocked blocked) {
    final serverMessage = blocked.message.trim();
    if (serverMessage.isNotEmpty) return serverMessage;

    return switch (blocked.rule) {
      AttendanceRule.mockLocationDetected => l10n.ruleMockLocationDetected,
      AttendanceRule.employeeNotFound => l10n.ruleEmployeeNotFound,
      AttendanceRule.noShiftAssigned => l10n.ruleNoShiftAssigned,
      AttendanceRule.outsideShiftHours => l10n.ruleOutsideShiftHours,
      AttendanceRule.overnightSessionDone => l10n.ruleOvernightSessionDone,
      AttendanceRule.sessionAlreadyStarted => l10n.ruleSessionAlreadyStarted,
      AttendanceRule.sessionAlreadyCompleted =>
        l10n.ruleSessionAlreadyCompleted,
      AttendanceRule.sessionAlreadyCheckedOut =>
        l10n.ruleSessionAlreadyCheckedOut,
      AttendanceRule.sessionNotStarted => l10n.ruleSessionNotStarted,
      AttendanceRule.afterCheckoutWindow => l10n.ruleAfterCheckoutWindow,
      AttendanceRule.earlyCheckoutRequiresReason =>
        l10n.ruleEarlyCheckoutRequiresReason,
    };
  }

  /// What to tell the user about a punch the backend stored.
  ///
  /// A `rejected` or `pending` punch reads as a warning, never as a success —
  /// §7 rule 5 is explicit that a stored-but-unverified punch has to look
  /// different from an accepted one.
  static String receipt(
    AppLocalizations l10n,
    PunchReceipt receipt,
    ClockAction action,
  ) {
    if (!receipt.isVerified) return _unverified(l10n, receipt);

    final session = receipt.sessionLabel;
    final base = switch (action) {
      ClockAction.clockIn =>
        session == null
            ? l10n.clockInSuccess
            : l10n.clockInSuccessInSession(session),
      ClockAction.clockOut =>
        session == null
            ? l10n.clockOutSuccess
            : l10n.clockOutSuccessInSession(session),
    };

    // Lateness is reported on clock-in only, and only once a shift exists.
    final lateMinutes = receipt.lateMinutes;
    if (receipt.isLate == true && lateMinutes != null && lateMinutes > 0) {
      return '$base · ${l10n.punchLateBy(lateMinutes)}';
    }

    return base;
  }

  static String _unverified(AppLocalizations l10n, PunchReceipt receipt) {
    if (receipt.verification == PunchVerification.pending) {
      return l10n.punchPendingVerification;
    }

    final reason = _rejection(l10n, receipt);
    return reason == null
        ? l10n.punchNotVerified
        : l10n.punchNotVerifiedBecause(reason);
  }

  /// The documented rejection reasons in the user's language; anything the
  /// backend adds later falls through as its raw code rather than vanishing.
  static String? _rejection(AppLocalizations l10n, PunchReceipt receipt) {
    return switch (receipt.rejectionReason) {
      PunchRejectionReason.outsideGeofence => l10n.rejectionOutsideGeofence,
      PunchRejectionReason.missingCoordinates =>
        l10n.rejectionMissingCoordinates,
      PunchRejectionReason.unknownWifi => l10n.rejectionUnknownWifi,
      PunchRejectionReason.missingBssid => l10n.rejectionMissingBssid,
      null => receipt.rawRejectionReason,
    };
  }

  /// The prompt on the early-checkout dialog, naming the cutoff when the
  /// backend supplied one (§7 rule 7).
  static String earlyCheckoutPrompt(
    AppLocalizations l10n,
    PunchBlockDetails details,
  ) {
    final earliest = detailTime(details.earliestCheckout);
    return earliest == null
        ? l10n.earlyCheckoutPrompt
        : l10n.earlyCheckoutPromptBefore(earliest);
  }

  /// `HH:mm` for the card's time columns, or a placeholder when the punch
  /// hasn't happened.
  static String clockTime(AppLocalizations l10n, DateTime? at) {
    if (at == null) return l10n.noTimeYet;
    return hourMinute(at);
  }

  /// A `details` value rendered for display: an RFC3339 stamp becomes a local
  /// `HH:mm`, anything else (`"17:30"`, a label) is passed through untouched.
  static String? detailTime(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    return parsed == null ? raw : hourMinute(parsed.toLocal());
  }

  /// Formatted by hand rather than through `DateFormat`: under the Lao locale
  /// that would render Lao numerals, which read oddly next to the ASCII times
  /// the rest of the card shows.
  static String hourMinute(DateTime at) {
    final hour = at.hour.toString().padLeft(2, '0');
    final minute = at.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// `HH:mm:ss` for the card's live clock, hand-formatted for the same
  /// reason as [hourMinute].
  static String hourMinuteSecond(DateTime at) {
    final second = at.second.toString().padLeft(2, '0');
    return '${hourMinute(at)}:$second';
  }
}
