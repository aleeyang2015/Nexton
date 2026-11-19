import 'package:flutter/material.dart';

import '../../../../core/l10n/failure_localizer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/datasources/leave_error_code.dart';
import '../../domain/entities/leave_approval_step.dart';
import '../../domain/entities/leave_duration_type.dart';
import '../../domain/entities/leave_request.dart';
import '../../domain/entities/leave_status.dart';
import '../../domain/entities/leave_type.dart';
import '../providers/leave_approvals_state.dart';

/// Turns leave domain values into the words and colours the time-off pages
/// show. Pure functions, no widgets — same split as `AttendanceCopy`.
class LeaveCopy {
  LeaveCopy._();

  static const _monthsShortLo = [
    'ມ.ກ.',
    'ກ.ພ.',
    'ມ.ນ.',
    'ມ.ສ.',
    'ພ.ພ.',
    'ມິ.ຖ.',
    'ກ.ລ.',
    'ສ.ຫ.',
    'ກ.ຍ.',
    'ຕ.ລ.',
    'ພ.ຈ.',
    'ທ.ວ.',
  ];

  static const _monthsShortEn = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// Sunday-first weekday initials for a calendar header, matching
  /// `DateTime.weekday % 7`.
  static const _weekdayInitialsLo = [
    'ອາ',
    'ຈ',
    'ອ',
    'ພ',
    'ພຫ',
    'ສຸ',
    'ສ',
  ];

  static const _weekdayInitialsEn = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  static bool _isLao(AppLocalizations l10n) => l10n.localeName.startsWith('lo');

  /// "25 ສ.ຫ. 2026" / "25 Aug 2026".
  static String shortDate(AppLocalizations l10n, DateTime date) {
    final month = (_isLao(l10n)
        ? _monthsShortLo
        : _monthsShortEn)[date.month - 1];
    return '${date.day} $month ${date.year}';
  }

  /// "12 ພ.ຈ. 14:05" / "12 Nov 14:05" — when an approval step was decided.
  /// Latin digits and a 24-hour clock in both languages.
  static String stepTime(AppLocalizations l10n, DateTime at) {
    final month = (_isLao(l10n) ? _monthsShortLo : _monthsShortEn)[at.month -
        1];
    final hour = at.hour.toString().padLeft(2, '0');
    final minute = at.minute.toString().padLeft(2, '0');
    return '${at.day} $month $hour:$minute';
  }

  /// "ສ.ຫ. 2026" / "Sep 2026" — the leave calendar's month heading.
  static String monthYearShort(AppLocalizations l10n, DateTime month) {
    final names = _isLao(l10n) ? _monthsShortLo : _monthsShortEn;
    return '${names[month.month - 1]} ${month.year}';
  }

  /// Sunday-first weekday initials for the leave calendar's header row.
  static List<String> weekdayInitials(AppLocalizations l10n) =>
      _isLao(l10n) ? _weekdayInitialsLo : _weekdayInitialsEn;

  /// The Lao name when the UI is in Lao and one exists, otherwise the default.
  ///
  /// The type inside a request carries no Lao name of its own, so a card
  /// showing a request passes the loaded [types] too: the name is then looked
  /// up by the type's id, falling back to what the request itself carries
  /// when the list has not loaded or no longer has that type.
  static String leaveTypeLabel(
    AppLocalizations l10n,
    LeaveType type, {
    List<LeaveType> types = const [],
  }) {
    if (!_isLao(l10n)) return type.name;

    if ((type.nameLo ?? '').isNotEmpty) return type.nameLo!;
    for (final known in types) {
      if (known.id == type.id && (known.nameLo ?? '').isNotEmpty) {
        return known.nameLo!;
      }
    }
    return type.name;
  }

  /// What to tell an approver whose approve or reject was refused, or null
  /// when there is nothing to tell (it went through) or nobody to tell (the
  /// approvals screen was closed before the answer came).
  ///
  /// The server's own reason, in the user's language. Two codes read
  /// differently here than to the employee who asks. `INVALID_STATUS` means,
  /// to an approver, that the request is no longer waiting. And
  /// `INSUFFICIENT_BALANCE` on an approve is about the employee's days, not
  /// the approver's: it says so, and what can be done (#70). A refusal with a
  /// code the App does not know shows the server's message.
  static String? decisionRefusal(
    AppLocalizations l10n,
    LeaveDecisionOutcome outcome,
  ) {
    if (outcome.kind == LeaveDecisionKind.success || outcome.abandoned) {
      return null;
    }

    final failure = outcome.failure;
    if (failure == null) return l10n.leaveApprovalDecideFailed;
    return switch (LeaveErrorCode.tokenOf(failure)) {
      LeaveErrorCode.tokenInvalidStatus => l10n.leaveApprovalNoLongerWaiting,
      LeaveErrorCode.tokenInsufficientBalance =>
        l10n.leaveApprovalInsufficientBalance,
      _ => failure.localize(l10n),
    };
  }

  /// Whether the approver has to say OK to [outcome]'s refusal, in a dialog
  /// that stays, rather than be told in a toast that is gone in three
  /// seconds. Only "not enough days left" (#70): it is two sentences, the
  /// request looks unchanged underneath, and it says what to do next.
  static bool refusalNeedsOk(LeaveDecisionOutcome outcome) {
    final failure = outcome.failure;
    return outcome.kind == LeaveDecisionKind.failed &&
        !outcome.abandoned &&
        failure != null &&
        LeaveErrorCode.tokenOf(failure) ==
            LeaveErrorCode.tokenInsufficientBalance;
  }

  /// "3 days" / "7.5 days" — or the half-day wording for exactly half a day.
  static String daysLabel(AppLocalizations l10n, double days) {
    if (days == 0.5) return l10n.leaveHalfDayLabel;
    return l10n.leaveDaysSuffix(dayCount(days));
  }

  /// A count of days as it is written: whole when it is whole (`3`), with its
  /// decimals when it has them (`7.5`, `7.25`), to two places at most. Latin
  /// digits in every language, formatted by hand like the dates.
  ///
  /// A balance is never rounded to a whole number the user does not have:
  /// 7.5 days left is not "8". Something that is not a number at all is a
  /// dash.
  static String dayCount(double days) {
    if (!days.isFinite) return '-';

    final text = days.toStringAsFixed(2);
    if (!text.contains('.')) return text;
    // "7.50" → "7.5", "3.00" → "3".
    return text.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  /// The date line under a history/approval card's title: a single date for a
  /// one-day request, a "start – end" range otherwise, each followed by the
  /// day count.
  static String dateLine(
    AppLocalizations l10n, {
    required DateTime startDate,
    required DateTime endDate,
    required double totalDays,
  }) {
    final isSingleDay =
        startDate.year == endDate.year &&
        startDate.month == endDate.month &&
        startDate.day == endDate.day;

    if (isSingleDay) {
      return '${shortDate(l10n, startDate)} • ${daysLabel(l10n, totalDays)}';
    }
    return '${shortDate(l10n, startDate)} – ${shortDate(l10n, endDate)} • '
        '${daysLabel(l10n, totalDays)}';
  }

  /// The days of a team row (#50): the date line for days in a row, else
  /// the days themselves, grouped by month: "1, 15 ກ.ຍ. 2026" / "1, 15 Sep
  /// 2026"; "28 Aug 2026, 2 Sep 2026" across months.
  static String teamDays(AppLocalizations l10n, LeaveRequest request) {
    // A day listed twice is one day.
    final days = {
      for (final d in request.requestDays) DateTime(d.year, d.month, d.day),
    }.toList()..sort();
    final inARow = days.length < 2 ||
        [
          for (var i = 1; i < days.length; i++)
            DateTime(days[i].year, days[i].month, days[i].day)
                .difference(
                  DateTime(days[i - 1].year, days[i - 1].month, days[i - 1].day),
                )
                .inDays,
        ].every((gap) => gap == 1);
    if (inARow) {
      return dateLine(
        l10n,
        startDate: request.startDate,
        endDate: request.endDate,
        totalDays: request.totalDays,
      );
    }
    final groups = <String>[];
    var i = 0;
    while (i < days.length) {
      final month = days[i];
      final sameMonth = <int>[];
      while (i < days.length &&
          days[i].year == month.year &&
          days[i].month == month.month) {
        sameMonth.add(days[i].day);
        i++;
      }
      final last = shortDate(l10n, DateTime(month.year, month.month, sameMonth.last));
      groups.add([...sameMonth.take(sameMonth.length - 1), last].join(', '));
    }
    return '${groups.join(', ')} • ${daysLabel(l10n, request.totalDays)}';
  }

  static String durationLabel(
    AppLocalizations l10n,
    LeaveDurationType duration,
  ) => switch (duration) {
    LeaveDurationType.fullDay => l10n.leaveDurationFullDay,
    LeaveDurationType.firstHalf => l10n.leaveDurationFirstHalf,
    LeaveDurationType.secondHalf => l10n.leaveDurationSecondHalf,
  };

  static String stepRoleLabel(AppLocalizations l10n, LeaveStepRole role) =>
      switch (role) {
        LeaveStepRole.deptHead => l10n.leaveStepDeptHead,
        LeaveStepRole.hr => l10n.leaveStepHr,
        LeaveStepRole.unknown => l10n.leaveStepManagerReview,
      };

  /// What the primary button on a pending approval card should say.
  ///
  /// The last step in the chain grants the leave outright, so it is named
  /// differently from a step that merely passes the request along.
  static String approveActionLabel(
    AppLocalizations l10n,
    LeaveRequest request,
  ) => request.isFinalApprovalStep
      ? l10n.leaveApprovalFinalAction
      : l10n.leaveApprovalApproveAction;

  static ({String label, Color color}) statusPill(
    AppLocalizations l10n,
    LeaveStatus status,
  ) {
    return switch (status) {
      LeaveStatus.pending => (
        label: l10n.leaveStatusPending,
        color: AppColors.primary,
      ),
      LeaveStatus.approved => (
        label: l10n.leaveStatusApproved,
        color: AppColors.success,
      ),
      LeaveStatus.rejected => (
        label: l10n.leaveStatusRejected,
        color: AppColors.danger,
      ),
      LeaveStatus.cancelled => (
        label: l10n.leaveStatusCancelled,
        color: AppColors.gray500,
      ),
    };
  }
}
