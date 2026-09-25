import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/time_correction_record.dart';
import '../../domain/entities/time_correction_status.dart';
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

  static String statusLabel(
    AppLocalizations l10n,
    TimeCorrectionStatus status,
  ) => switch (status) {
    TimeCorrectionStatus.pending => l10n.timeCorrectionStatusPending,
    TimeCorrectionStatus.approved => l10n.timeCorrectionStatusApproved,
    TimeCorrectionStatus.rejected => l10n.timeCorrectionStatusRejected,
    TimeCorrectionStatus.cancelled => l10n.timeCorrectionStatusCancelled,
  };

  static Color statusColor(TimeCorrectionStatus status) => switch (status) {
    TimeCorrectionStatus.pending => AppColors.primaryVariant,
    TimeCorrectionStatus.approved => AppColors.attendancePresent,
    TimeCorrectionStatus.rejected => AppColors.danger,
    TimeCorrectionStatus.cancelled => AppColors.gray600,
  };

  /// A history tab's label with its count — "ລໍຖ້າ (4)"; null is "all".
  static String filterLabel(
    AppLocalizations l10n,
    TimeCorrectionStatus? status,
    int count,
  ) => switch (status) {
    null => l10n.timeCorrectionFilterAll(count),
    TimeCorrectionStatus.pending => l10n.timeCorrectionFilterPending(count),
    TimeCorrectionStatus.approved => l10n.timeCorrectionFilterApproved(count),
    TimeCorrectionStatus.rejected => l10n.timeCorrectionFilterRejected(count),
    TimeCorrectionStatus.cancelled =>
      '${l10n.timeCorrectionStatusCancelled} ($count)',
  };

  /// "#d290" — a long id (a UUID) cut to its first four characters, as the
  /// design shows it; a short id is shown whole.
  static String shortId(String id) =>
      '#${id.length > 8 ? id.substring(0, 4) : id}';

  /// "24/09/2026 10:45" — when a request was sent.
  static String submittedAt(DateTime at) =>
      '${_two(at.day)}/${_two(at.month)}/${at.year} '
      '${_two(at.hour)}:${_two(at.minute)}';

  /// The corrected time(s) a history card shows, with the icon that goes
  /// before them: "08:00 - 12:00" for both, "ເຂົ້າ 08:00" for one side.
  static ({IconData icon, String label})? recordTimes(
    AppLocalizations l10n,
    TimeCorrectionRecord record,
  ) {
    final clockIn = record.type.needsClockIn ? record.clockIn : null;
    final clockOut = record.type.needsClockOut ? record.clockOut : null;
    if (clockIn != null && clockOut != null) {
      return (
        icon: Icons.schedule,
        label: '${_duration(clockIn)} - ${_duration(clockOut)}',
      );
    }
    if (clockIn != null) {
      return (
        icon: Icons.login,
        label: l10n.timeCorrectionClockInAt(_duration(clockIn)),
      );
    }
    if (clockOut != null) {
      return (
        icon: Icons.logout,
        label: l10n.timeCorrectionClockOutAt(_duration(clockOut)),
      );
    }
    return null;
  }

  /// "08:00" from an offset since midnight.
  static String hourMinuteOf(Duration offset) => _duration(offset);

  static String _duration(Duration offset) =>
      '${_two(offset.inHours)}:${_two(offset.inMinutes % 60)}';

  static String _two(int value) => value.toString().padLeft(2, '0');
}
