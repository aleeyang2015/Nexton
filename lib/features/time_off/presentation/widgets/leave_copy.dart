import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/leave_approval_step.dart';
import '../../domain/entities/leave_duration_type.dart';
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

  static bool _isLao(AppLocalizations l10n) => l10n.localeName.startsWith('lo');

  /// "25 ສ.ຫ. 2026" / "25 Aug 2026".
  static String shortDate(AppLocalizations l10n, DateTime date) {
    final month = (_isLao(l10n)
        ? _monthsShortLo
        : _monthsShortEn)[date.month - 1];
    return '${date.day} $month ${date.year}';
  }

  /// The Lao name when the UI is in Lao and one exists, otherwise the default.
  static String leaveTypeLabel(AppLocalizations l10n, LeaveType type) {
    if (_isLao(l10n) && (type.nameLo ?? '').isNotEmpty) return type.nameLo!;
    return type.name;
  }

  /// "3 days" / "0.5 days" — a whole count of days, or the half-day wording.
  static String daysLabel(AppLocalizations l10n, double days) {
    if (days == 0.5) return l10n.leaveHalfDayLabel;
    return l10n.leaveDaysSuffix(days.round());
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
