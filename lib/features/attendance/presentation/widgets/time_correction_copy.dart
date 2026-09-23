import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/time_correction_type.dart';
import 'attendance_history_copy.dart';

/// Words and formats for the time-correction request form. Pure functions,
/// no widgets — same split as [AttendanceHistoryCopy]. Times are formatted by
/// hand for the reason [AttendanceHistoryCopy] gives.
class TimeCorrectionCopy {
  TimeCorrectionCopy._();

  static String typeLabel(AppLocalizations l10n, TimeCorrectionType type) =>
      switch (type) {
        TimeCorrectionType.forgotClockIn => l10n.timeCorrectionTypeForgotIn,
        TimeCorrectionType.forgotClockOut => l10n.timeCorrectionTypeForgotOut,
        TimeCorrectionType.both => l10n.timeCorrectionTypeBoth,
        TimeCorrectionType.wrongTime => l10n.timeCorrectionTypeWrongTime,
      };

  static IconData typeIcon(TimeCorrectionType type) => switch (type) {
    TimeCorrectionType.forgotClockIn => Icons.login,
    TimeCorrectionType.forgotClockOut => Icons.logout,
    TimeCorrectionType.both => Icons.swap_horiz,
    TimeCorrectionType.wrongTime => Icons.history_toggle_off,
  };

  /// "ວັນສຸກ · 18/09/2026" under the picked date.
  static String dateSubtitle(AppLocalizations l10n, DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '${AttendanceHistoryCopy.weekday(l10n, date)} · $day/$month/${date.year}';
  }

  /// "08:00" — 24-hour, as the time field shows it.
  static String hourMinute(TimeOfDay time) =>
      '${_two(time.hour)}:${_two(time.minute)}';

  /// "08:00 AM (ຕອນເຊົ້າ)" — the caption under a time field.
  static String caption(AppLocalizations l10n, TimeOfDay time) {
    final hour12 = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final suffix = time.period == DayPeriod.am ? 'AM' : 'PM';
    final part = time.hour < 12
        ? l10n.timeCorrectionMorning
        : time.hour < 18
        ? l10n.timeCorrectionAfternoon
        : l10n.timeCorrectionEvening;
    return '${_two(hour12)}:${_two(time.minute)} $suffix ($part)';
  }

  /// "1.2 MB" / "340 KB" for the picked file's size.
  static String fileSize(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).ceil()} KB';
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}
