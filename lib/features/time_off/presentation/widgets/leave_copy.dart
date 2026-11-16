import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/leave_approval_step.dart';
import '../../domain/entities/leave_duration_type.dart';
import '../../domain/entities/leave_request.dart';
import '../../domain/entities/leave_status.dart';
import '../../domain/entities/leave_type.dart';

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

  /// "3 days" / "7.5 days" — or the half-day wording for exactly half a day.
  static String daysLabel(AppLocalizations l10n, double days) {
    if (days == 0.5) return l10n.leaveHalfDayLabel;
    return l10n.leaveDaysSuffix(dayCount(days));
  }

  /// A count of days as it is written: whole when it is whole (`3`), with one
  /// decimal when it is not (`7.5`). Latin digits in every language, formatted
  /// by hand like the dates, and never rounded to a number the user does not
  /// have.
  static String dayCount(double days) =>
      days == days.roundToDouble()
      ? days.round().toString()
      : days.toStringAsFixed(1);

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
