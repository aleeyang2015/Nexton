import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../features/profile/domain/entities/shift_detail.dart';
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

  /// The card header's badge, from the real `is_late` flag `records/my`
  /// reports on today's sessions.
  ///
  /// `attendance_status` (`present`/`late`/`absent`) would be the more
  /// direct source, but the spec is explicit that it's clock-in-only —
  /// `records/my` never carries it (§6.2/§3's field table) — so `is_late`
  /// is the closest real signal available for a day that's already loaded.
  ///
  /// On time, the badge names the employee's actual assigned shift
  /// (`/core_hr/employees/me`'s `shift.name`/`shift.name_lo`) rather than a
  /// generic "on time" label — [AppLocalizations.regularTimeBadge] is only
  /// the fallback for when that hasn't loaded or no shift is assigned.
  static ({String label, Color color}) statusBadge(
    AppLocalizations l10n,
    AttendanceDay day, {
    String? shiftName,
  }) {
    if (day.isLate) {
      return (
        label: l10n.attendanceLateStatus,
        color: AppColors.attendanceLate,
      );
    }

    final label = (shiftName != null && shiftName.isNotEmpty)
        ? shiftName
        : l10n.regularTimeBadge;
    return (label: label, color: AppColors.attendancePresent);
  }

  /// The assigned shift's own name (`shift.name`/`shift.name_lo`) in the
  /// user's language, or null when the employee has no shift on file (yet,
  /// or ever).
  static String? employeeShiftName(
    Locale locale,
    String? name,
    String? nameLo,
  ) {
    final picked = _pickLocalized(locale, name, nameLo);
    return picked.isEmpty ? null : picked;
  }

  /// Today's shift-hours line for the card, from the real `session_label`s
  /// `records/my` returns (§6.2's note recommends showing this rather than
  /// the raw session order).
  ///
  /// Before the first punch of the day there are no sessions to read a label
  /// from, so this falls back to the employee's assigned shift
  /// (`/core_hr/employees/me`'s `shift.shift_details[]`) — the real "ກະເຊົ້າ
  /// 08:00-12:00 | ກະແລງ 13:00-17:00" for *this* employee, not a canned
  /// example. [AppLocalizations.shiftHoursPlaceholder] is the last resort,
  /// for when even that hasn't loaded.
  static String shiftHoursLine(
    AppLocalizations l10n,
    Locale locale,
    List<AttendanceSession> sessions,
    List<ShiftDetail> shiftDetails,
  ) {
    final labels = sessions
        .map((s) => s.label)
        .whereType<String>()
        .where((label) => label.isNotEmpty)
        .toList(growable: false);

    if (labels.isNotEmpty) return labels.join(' | ');

    final shiftLines = shiftDetails
        .map((detail) => shiftDetailLine(locale, detail))
        .where((line) => line.isNotEmpty)
        .toList(growable: false);

    return shiftLines.isEmpty
        ? l10n.shiftHoursPlaceholder
        : shiftLines.join(' | ');
  }

  /// One shift segment as shown on screen — its localized name, plus its
  /// scheduled hours when the backend sent them (e.g. `"ກະເຊົ້າ: 08:00 -
  /// 12:00"`).
  static String shiftDetailLine(Locale locale, ShiftDetail detail) {
    final name = shiftDetailName(locale, detail);
    final start = _shiftClockTime(detail.startTime);
    final end = _shiftClockTime(detail.endTime);
    final range = [
      if (start != null) start,
      if (end != null) end,
    ].join(' - ');

    if (name.isEmpty) return range;
    return range.isEmpty ? name : '$name: $range';
  }

  /// `name` or `name_lo`, following the app's language — Lao prefers
  /// `name_lo`, everything else prefers `name`, each falling back to
  /// whichever of the two the backend actually sent.
  static String shiftDetailName(Locale locale, ShiftDetail detail) {
    return _pickLocalized(locale, detail.name, detail.nameLo);
  }

  /// `name` or `name_lo` by locale — Lao prefers `name_lo`, everything else
  /// prefers `name` — falling back to whichever of the two is actually set.
  /// Shared by every "name or name_lo" field the API sends (a shift's own
  /// name, a shift segment's name, …).
  static String _pickLocalized(Locale locale, String? name, String? nameLo) {
    final preferred = locale.languageCode == 'lo' ? nameLo : name;
    if (preferred != null && preferred.isNotEmpty) return preferred;

    final fallback = locale.languageCode == 'lo' ? name : nameLo;
    return fallback ?? '';
  }

  /// A shift's raw `HH:mm[:ss]` schedule string as `HH:mm`, hand-trimmed for
  /// the same reason [hourMinute] is hand-formatted rather than parsed
  /// through `DateTime` — it isn't one, it's a time-of-day with no date.
  static String? _shiftClockTime(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final match = RegExp(r'^(\d{2}:\d{2})').firstMatch(raw);
    return match?.group(1) ?? raw;
  }

  /// A clock method code (`"gps"`, `"wifi"`, …) in the user's language, for
  /// the methods row and the history list's per-session chip. Unrecognised
  /// codes pass through as-is, so a method the backend adds later still
  /// shows something rather than vanishing.
  static String methodLabel(AppLocalizations l10n, String method) {
    return switch (method) {
      'gps' => l10n.methodGps,
      'wifi' => l10n.methodWifi,
      'biometric' => l10n.methodBiometric,
      'field' => l10n.methodField,
      _ => method,
    };
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
