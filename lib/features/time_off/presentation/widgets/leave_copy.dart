import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/leave_category.dart';
import '../../domain/entities/leave_status.dart';

/// Turns leave domain values into the words and colours the time-off pages
/// show. Pure functions, no widgets — same split as `AttendanceCopy`.
class LeaveCopy {
  LeaveCopy._();

  static const _monthsShortLo = [
    'ມ.ກ.', 'ກ.ພ.', 'ມ.ນ.', 'ມ.ສ.', 'ພ.ພ.', 'ມິ.ຖ.',
    'ກ.ລ.', 'ສ.ຫ.', 'ກ.ຍ.', 'ຕ.ລ.', 'ພ.ຈ.', 'ທ.ວ.',
  ];

  static const _monthsShortEn = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static bool _isLao(AppLocalizations l10n) => l10n.localeName.startsWith('lo');

  /// "25 ສ.ຫ. 2026" / "25 Aug 2026".
  static String shortDate(AppLocalizations l10n, DateTime date) {
    final month = (_isLao(l10n) ? _monthsShortLo : _monthsShortEn)[date.month - 1];
    return '${date.day} $month ${date.year}';
  }

  /// The date line under a history/approval card's title: a single date for
  /// a one-day request, a "start – end" range otherwise, each followed by
  /// the day count (only a single day skips the "total" wording).
  static String dateLine(
    AppLocalizations l10n, {
    required DateTime startDate,
    required DateTime endDate,
    required int totalDays,
  }) {
    final isSingleDay =
        startDate.year == endDate.year &&
        startDate.month == endDate.month &&
        startDate.day == endDate.day;

    if (isSingleDay) {
      return '${shortDate(l10n, startDate)} • ${l10n.leaveDaysSuffix(totalDays)}';
    }
    return '${shortDate(l10n, startDate)} – ${shortDate(l10n, endDate)} • '
        '${l10n.leaveTotalDaysSuffix(totalDays)}';
  }

  static String categoryLabel(AppLocalizations l10n, LeaveCategory category) {
    return switch (category) {
      LeaveCategory.annual => l10n.leaveCategoryAnnual,
      LeaveCategory.sick => l10n.leaveCategorySick,
      LeaveCategory.personal => l10n.leaveCategoryPersonal,
      LeaveCategory.rest => l10n.leaveCategoryRest,
    };
  }

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
    };
  }
}
