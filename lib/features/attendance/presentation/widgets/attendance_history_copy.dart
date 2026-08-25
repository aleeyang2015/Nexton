import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/attendance_day.dart';

/// Turns a day's raw attendance fields into the words and colour the history
/// page's badges and status pill show. Pure functions, no widgets — same
/// split as [AttendanceCopy].
///
/// Month and weekday names are a hand-written Lao/English table rather than
/// `DateFormat`, for the same reason [AttendanceCopy.hourMinute] hand-formats
/// times: this app's Lao locale has no digit data in `intl`, and mixing a
/// library-formatted year into an otherwise hand-formatted date risked one
/// digit style for the year and another for everything else.
class AttendanceHistoryCopy {
  AttendanceHistoryCopy._();

  static const _monthsLo = [
    'ມັງກອນ', 'ກຸມພາ', 'ມີນາ', 'ເມສາ', 'ພຶດສະພາ', 'ມິຖຸນາ',
    'ກໍລະກົດ', 'ສິງຫາ', 'ກັນຍາ', 'ຕຸລາ', 'ພະຈິກ', 'ທັນວາ',
  ];

  static const _monthsShortLo = [
    'ມ.ກ.', 'ກ.ພ.', 'ມ.ນ.', 'ມ.ສ.', 'ພ.ພ.', 'ມິ.ຖ.',
    'ກ.ລ.', 'ສ.ຫ.', 'ກ.ຍ.', 'ຕ.ລ.', 'ພ.ຈ.', 'ທ.ວ.',
  ];

  static const _monthsEn = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static const _monthsShortEn = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// Sunday-first, matching `DateTime.weekday % 7`.
  static const _weekdaysLo = [
    'ວັນອາທິດ', 'ວັນຈັນ', 'ວັນອັງຄານ', 'ວັນພຸດ', 'ວັນພະຫັດ', 'ວັນສຸກ', 'ວັນເສົາ',
  ];

  static const _weekdaysShortLo = [
    'ອາທິດ', 'ຈັນ', 'ອັງຄານ', 'ພຸດ', 'ພະຫັດ', 'ສຸກ', 'ເສົາ',
  ];

  static const _weekdaysEn = [
    'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday',
  ];

  static const _weekdaysShortEn = [
    'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat',
  ];

  static bool _isLao(AppLocalizations l10n) => l10n.localeName.startsWith('lo');

  /// "ມິຖຸນາ 2026" / "June 2026" for the month switcher.
  static String monthYear(AppLocalizations l10n, DateTime month) {
    final names = _isLao(l10n) ? _monthsLo : _monthsEn;
    return '${names[month.month - 1]} ${month.year}';
  }

  /// "ວັນເສົາ 22 ມິ.ຖ." / "Sat 22 Jun" for a day row's title line.
  static String dayTitle(AppLocalizations l10n, DateTime date) {
    final lao = _isLao(l10n);
    final weekday = (lao ? _weekdaysLo : _weekdaysEn)[date.weekday % 7];
    final month = (lao ? _monthsShortLo : _monthsShortEn)[date.month - 1];
    return '$weekday ${date.day} $month';
  }

  /// The day badge's short weekday label — "ເສົາ" / "Sat".
  static String weekdayShort(AppLocalizations l10n, DateTime date) {
    return (_isLao(l10n) ? _weekdaysShortLo : _weekdaysShortEn)[date.weekday % 7];
  }

  /// A standard day is 8 hours — the same shift length
  /// `AttendanceStatusCard`'s `shiftHoursPlaceholder` assumes, until a real
  /// shift/schedule endpoint exists. Worked time beyond that reads as
  /// overtime.
  static const double standardWorkHours = 8;

  /// The one status pill a day's row shows. Priority: an early exit or a
  /// late arrival is the more actionable fact, so either outranks overtime;
  /// a day with neither reads as a plain, on-time "present".
  ///
  /// Exact minutes/hours show only when the backend reports them ([lateMinutes]-
  /// style fields); otherwise the pill still names the status without a
  /// fabricated number.
  static ({String label, Color color}) status(
    AppLocalizations l10n,
    AttendanceDay day,
  ) {
    if (day.isEarlyExit) {
      final minutes = day.earlyExitMinutes;
      return (
        label: minutes == null
            ? l10n.attendanceEarlyExitStatus
            : l10n.attendanceEarlyExitByMinutes(minutes),
        color: AppColors.gray600,
      );
    }

    if (day.isLate) {
      final minutes = day.lateMinutes;
      return (
        label: minutes == null
            ? l10n.attendanceLateStatus
            : l10n.attendanceLateByMinutes(minutes),
        color: AppColors.attendanceLate,
      );
    }

    final overtime = _overtimeHours(day.totalWorkHours);
    if (overtime != null) {
      return (
        label: l10n.attendanceOvertimeHours(overtime.toStringAsFixed(1)),
        // Reuses the "absent" red: on this page red means "stands out from
        // a plain day", not specifically an absence.
        color: AppColors.attendanceAbsent,
      );
    }

    return (
      label: l10n.attendancePresentStatus,
      color: AppColors.attendancePresent,
    );
  }

  static double? _overtimeHours(double? totalWorkHours) {
    if (totalWorkHours == null) return null;
    final extra = totalWorkHours - standardWorkHours;
    return extra > 0 ? extra : null;
  }
}
