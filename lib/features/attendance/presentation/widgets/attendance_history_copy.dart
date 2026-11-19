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

  /// "18 ກັນຍາ 2026" / "18 September 2026".
  static String dayMonthYear(AppLocalizations l10n, DateTime date) {
    final names = _isLao(l10n) ? _monthsLo : _monthsEn;
    return '${date.day} ${names[date.month - 1]} ${date.year}';
  }

  /// The full weekday name — "ວັນສຸກ" / "Friday".
  static String weekday(AppLocalizations l10n, DateTime date) {
    return (_isLao(l10n) ? _weekdaysLo : _weekdaysEn)[date.weekday % 7];
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

  /// An hour count with at most one decimal: `1.5`, and `2` or `0` rather
  /// than `2.0` or `0.0`. Hours are never below zero: a negative count, or
  /// one that would round to "-0", reads `0`.
  static String hours(double value) {
    if (value <= 0) return '0';
    final text = value.toStringAsFixed(1);
    return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
  }

  /// The "OT 1.5 h" line under a day, or null when the day has no approved
  /// OT to show.
  ///
  /// The hours are the server's `overtime_hours` and nothing else: a long
  /// day without approved OT has none, and the line is never worked out from
  /// the hours worked. An amount too small to show as a number (under 0.05 h)
  /// shows no line rather than "OT 0 h".
  static String? overtimeLine(AppLocalizations l10n, AttendanceDay day) {
    if (day.overtimeHours <= 0) return null;
    final text = hours(day.overtimeHours);
    return text == '0' ? null : l10n.attOvertimeHoursLine(text);
  }

  /// The day statuses the backend rolls a record up to that the pill names
  /// outright. `present` and `late` are not here: for those the pill is
  /// decided by the late and early-exit flags below.
  static const String _statusAbsent = 'absent';
  static const String _statusIncomplete = 'incomplete';
  static const String _statusHalfDay = 'half_day';
  static const String _statusLate = 'late';

  /// The one status pill a day's row shows.
  ///
  /// The backend's own verdict on the day comes first: a day it stored as
  /// absent, incomplete or a half day says so, whatever its punches look
  /// like — a day with only a clock-out is absent, not "present". For a day
  /// that was worked (`present`, `late`, or a status this app does not know)
  /// a late arrival outranks an early exit, and a day with neither is a
  /// plain "present". A day the backend calls `late` is late even when no
  /// session carries the flag.
  ///
  /// There is no overtime pill. Time worked past the shift is not overtime
  /// unless it was approved; approved OT has its own line, [overtimeLine].
  ///
  /// Exact minutes show only when the backend reports them; otherwise the
  /// pill still names the status without a fabricated number.
  static ({String label, Color color}) status(
    AppLocalizations l10n,
    AttendanceDay day,
  ) {
    final dayStatus = day.status?.trim().toLowerCase();
    switch (dayStatus) {
      case _statusAbsent:
        return (
          label: l10n.attendanceAbsentStatus,
          color: AppColors.attendanceAbsent,
        );
      case _statusIncomplete:
        return (
          label: l10n.attendanceIncompleteStatus,
          color: AppColors.attendanceLate,
        );
      case _statusHalfDay:
        return (
          label: l10n.attendanceHalfDayStatus,
          color: AppColors.gray600,
        );
    }

    if (day.isLate || dayStatus == _statusLate) {
      final minutes = day.lateMinutes;
      return (
        label: minutes == null
            ? l10n.attendanceLateStatus
            : l10n.attendanceLateByMinutes(minutes),
        color: AppColors.attendanceLate,
      );
    }

    if (day.isEarlyExit) {
      final minutes = day.earlyExitMinutes;
      return (
        label: minutes == null
            ? l10n.attendanceEarlyExitStatus
            : l10n.attendanceEarlyExitByMinutes(minutes),
        color: AppColors.gray600,
      );
    }

    return (
      label: l10n.attendancePresentStatus,
      color: AppColors.attendancePresent,
    );
  }
}
