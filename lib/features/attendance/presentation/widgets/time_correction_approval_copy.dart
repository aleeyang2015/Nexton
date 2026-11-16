import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/time_correction_detail.dart';
import '../../domain/entities/time_correction_status.dart';
import '../../domain/entities/time_correction_type.dart';
import 'time_correction_copy.dart';
import 'time_correction_detail_copy.dart';

/// Words, colours and formats for the approvals page. Pure functions, no
/// widgets — same split as [TimeCorrectionCopy].
class TimeCorrectionApprovalCopy {
  TimeCorrectionApprovalCopy._();

  static bool _isLao(AppLocalizations l10n) => l10n.localeName.startsWith('lo');

  /// The card's status pill — "ລໍຖ້າກວດສອບ" while pending.
  static ({String label, Color color}) status(
    AppLocalizations l10n,
    TimeCorrectionStatus status,
  ) => (
    label: status == TimeCorrectionStatus.pending
        ? l10n.timeCorrectionApprovalStatusPending
        : TimeCorrectionCopy.statusLabel(l10n, status),
    color: TimeCorrectionDetailCopy.statusColor(status),
  );

  /// The correction-type chip: "ລືມລົງເວລາອອກ (Missing Out)" in red, the
  /// in-side in green, both in blue.
  static ({String label, IconData icon, Color color}) type(
    AppLocalizations l10n,
    TimeCorrectionType type,
  ) => switch (type) {
    TimeCorrectionType.forgotClockIn => (
      label: l10n.timeCorrectionApprovalTypeMissingIn,
      icon: Icons.login,
      color: AppColors.attendancePresent,
    ),
    TimeCorrectionType.forgotClockOut => (
      label: l10n.timeCorrectionApprovalTypeMissingOut,
      icon: Icons.logout,
      color: AppColors.danger,
    ),
    TimeCorrectionType.both => (
      label: l10n.timeCorrectionApprovalTypeBoth,
      icon: Icons.swap_horiz,
      color: AppColors.primaryVariant,
    ),
    TimeCorrectionType.wrongTime => (
      label: l10n.timeCorrectionApprovalTypeWrongTime,
      icon: Icons.history_toggle_off,
      color: AppColors.attendanceLate,
    ),
  };

  /// "16/09/2026" — the day being corrected.
  static String date(DateTime date) =>
      '${_two(date.day)}/${_two(date.month)}/${date.year}';

  /// "ກະ morning (08:00 - 12:00)" — the shift segment, or null when the
  /// request carries none.
  static String? shiftSegment(
    AppLocalizations l10n,
    TimeCorrectionShift? shift,
  ) {
    if (shift == null) return null;
    final name = _isLao(l10n) ? shift.nameLo ?? shift.name : shift.name;
    final hours = TimeCorrectionDetailCopy.shiftHours(shift);
    if (name == null && hours == null) return null;
    return l10n.timeCorrectionApprovalShift(name ?? '', hours ?? '');
  }

  /// "REG ບໍລິຫານ" — the shift's code and name, or null when there is
  /// neither.
  static String? shiftGroup(AppLocalizations l10n, TimeCorrectionShift? shift) {
    if (shift == null) return null;
    final name = _isLao(l10n)
        ? shift.shiftNameLo ?? shift.shiftName
        : shift.shiftName;
    final text = [shift.shiftCode, name].whereType<String>().join(' ');
    return text.isEmpty ? null : text;
  }

  /// "ພະແນກ: haltech", or null when the employee has no department.
  static String? department(
    AppLocalizations l10n,
    TimeCorrectionEmployee employee,
  ) {
    final name = _isLao(l10n)
        ? employee.departmentNameLo ?? employee.departmentName
        : employee.departmentName;
    return name == null ? null : l10n.timeCorrectionApprovalDepartment(name);
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}
