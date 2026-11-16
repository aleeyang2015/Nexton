import 'package:flutter/material.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/failure_localizer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/profile/domain/entities/shift_detail.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/attendance_failure_x.dart';
import '../../domain/entities/attendance_day.dart';
import '../../domain/entities/punch_outcome.dart';
import '../../domain/entities/punch_receipt.dart';

/// Turns attendance domain values into the words the card and its dialogs
/// show. Pure functions, no widgets — the mapping is testable on its own and
/// the widgets stay small.
///
/// A refused punch is told in the user's language: the backend's `message`
/// is always English, so every rule the app knows has its own text here,
/// filled from `error.details` where the backend says a time ("clock-in opens
/// at 07:00"). The server's sentence is shown only for a code the app does not
/// know, and such a code never becomes a [PunchBlocked] in the first place.
class AttendanceCopy {
  AttendanceCopy._();

  /// What to say when a month's attendance (the summary or the daily list)
  /// could not be loaded, and whether trying again can help.
  ///
  /// A login with no employee record is told so, with no Retry: only HR can
  /// link the account. Anything else is "could not load" with a Retry.
  static ({String message, bool canRetry}) monthLoadFailure(
    AppLocalizations l10n,
    Object? error,
  ) {
    if (error is Failure && error.isEmployeeNotLinked) {
      return (message: error.localize(l10n), canRetry: false);
    }
    return (message: l10n.attSummaryLoadFailed, canRetry: true);
  }

  /// What to tell the user about a refused punch: the app's text for the
  /// rule, never the server's English.
  static String rule(AppLocalizations l10n, PunchBlocked blocked) =>
      ruleFallback(l10n, blocked.rule, blocked.details);

  /// The app's own wording for [rule], naming the time from [details] where
  /// the backend sent one.
  ///
  /// Public because the off-site scan form is refused by the same rules (its
  /// POST is gated by the same session guard) and must not invent a second set
  /// of words for them.
  static String ruleFallback(
    AppLocalizations l10n,
    AttendanceRule rule,
    PunchBlockDetails details,
  ) {
    return switch (rule) {
      AttendanceRule.mockLocationDetected => l10n.ruleMockLocationDetected,
      AttendanceRule.employeeNotFound => l10n.ruleEmployeeNotFound,
      AttendanceRule.noShiftAssigned => l10n.ruleNoShiftAssigned,
      AttendanceRule.outsideShiftHours => switch (detailTime(
        details.lastShiftEnd,
      )) {
        final String ended => l10n.ruleOutsideShiftHoursAt(ended),
        null => l10n.ruleOutsideShiftHours,
      },
      AttendanceRule.overnightSessionDone => l10n.ruleOvernightSessionDone,
      AttendanceRule.sessionAlreadyStarted => l10n.ruleSessionAlreadyStarted,
      AttendanceRule.sessionAlreadyCompleted =>
        l10n.ruleSessionAlreadyCompleted,
      AttendanceRule.sessionAlreadyCheckedOut =>
        l10n.ruleSessionAlreadyCheckedOut,
      AttendanceRule.sessionNotStarted => l10n.ruleSessionNotStarted,
      AttendanceRule.afterCheckoutWindow => switch (detailTime(
        details.latestCheckout,
      )) {
        final String until => l10n.ruleAfterCheckoutWindowAt(until),
        null => l10n.ruleAfterCheckoutWindow,
      },
      AttendanceRule.earlyCheckoutRequiresReason =>
        l10n.ruleEarlyCheckoutRequiresReason,
      AttendanceRule.outsideWorkArea => l10n.ruleOutsideWorkArea,
      AttendanceRule.offsiteRequestExists => l10n.ruleOffsiteRequestExists,
      // §3 asks for the opening time to be named so the user knows when to
      // come back; without it the message can only say "not yet".
      AttendanceRule.tooEarlyCheckin => switch (detailTime(
        details.clockInOpens,
      )) {
        final String opens => l10n.ruleTooEarlyCheckinAt(opens),
        null => l10n.ruleTooEarlyCheckin,
      },
      AttendanceRule.clockOutBeforeClockIn => switch (detailTime(
        details.clockIn,
      )) {
        final String at => l10n.ruleClockOutBeforeClockInAt(at),
        null => l10n.ruleClockOutBeforeClockIn,
      },
      AttendanceRule.otChanged => l10n.ruleOtChanged,
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

  /// The card header's badge: the employee's assigned shift name
  /// (`/core_hr/employees/me`'s `shift.name`/`shift.name_lo`), already
  /// resolved to the app's language by the caller.
  ///
  /// It never reports lateness — [AppLocalizations.regularTimeBadge] is only
  /// the fallback for when the shift hasn't loaded or none is assigned.
  static ({String label, Color color}) statusBadge(
    AppLocalizations l10n, {
    String? shiftName,
  }) {
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

  /// One shift segment as shown on screen — its localized name, plus its
  /// scheduled hours when the backend sent them (e.g. `"ກະເຊົ້າ: 08:00 -
  /// 12:00"`).
  static String shiftDetailLine(Locale locale, ShiftDetail detail) {
    final name = shiftDetailName(locale, detail);
    final range = shiftDetailHours(detail);

    if (name.isEmpty) return range;
    return range.isEmpty ? name : '$name: $range';
  }

  /// A shift segment's scheduled hours, e.g. `"08:00 - 12:00"`, or empty when
  /// the backend sent neither end.
  ///
  /// With [day], the hours are that weekday's own when HR set them
  /// ([ShiftDetail.timesOn]): on a Saturday that closes at noon the card must
  /// not say 17:00. Without it, the part's usual hours.
  static String shiftDetailHours(ShiftDetail detail, {DateTime? day}) {
    final times = day == null
        ? (start: detail.startTime, end: detail.endTime)
        : detail.timesOn(day);
    final start = _shiftClockTime(times.start);
    final end = _shiftClockTime(times.end);
    return [if (start != null) start, if (end != null) end].join(' - ');
  }

  /// `name` or `name_lo`, following the app's language — Lao prefers
  /// `name_lo`, everything else prefers `name`, each falling back to
  /// whichever of the two the backend actually sent.
  static String shiftDetailName(Locale locale, ShiftDetail detail) {
    return _pickLocalized(locale, detail.name, detail.nameLo);
  }

  /// The name of the shift part a history row's session belongs to, in the
  /// app's language, or null when the session has no shift part (or the
  /// backend named none) — the row then falls back to its position.
  static String? sessionPartName(Locale locale, AttendanceSession session) {
    final picked = _pickLocalized(locale, session.partName, session.partNameLo);
    return picked.isEmpty ? null : picked;
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

  /// A `details` time rendered for display, or null when there is nothing
  /// fit to show — the caller then uses the wording that names no time.
  ///
  /// The backend sends these as the company's wall clock, `HH:MM` (seconds
  /// are dropped when present). A full date-time stamp becomes a local
  /// `HH:mm`. Since every refusal's text is now built from these, anything
  /// that is not a time is left out rather than shown: a bare number, or the
  /// zero date a missing value serialises to. Other text (a label) passes
  /// through untouched.
  static String? detailTime(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return null;

    final clock = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2})?$').firstMatch(value);
    if (clock != null) {
      return '${clock.group(1)!.padLeft(2, '0')}:${clock.group(2)}';
    }

    // `DateTime.tryParse` reads "20261116" as a date; a number is not a time.
    if (RegExp(r'^[\d.]+$').hasMatch(value)) return null;

    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    // Go's zero time, sent for a value the backend did not have.
    if (parsed.year <= 1) return null;
    return hourMinute(parsed.toLocal());
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
