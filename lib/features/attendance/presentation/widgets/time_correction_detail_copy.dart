import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../time_off/domain/entities/leave_approval_step.dart';
import '../../domain/entities/time_correction_detail.dart';
import '../../domain/entities/time_correction_status.dart';
import 'time_correction_copy.dart';

/// Words and formats for the time-correction detail page. Pure functions, no
/// widgets — same split as [TimeCorrectionCopy].
class TimeCorrectionDetailCopy {
  TimeCorrectionDetailCopy._();

  static bool _isLao(AppLocalizations l10n) => l10n.localeName.startsWith('lo');

  /// The header pill reads amber while pending, as the design shows it.
  static Color statusColor(TimeCorrectionStatus status) =>
      status == TimeCorrectionStatus.pending
      ? AppColors.attendanceLate
      : TimeCorrectionCopy.statusColor(status);

  /// "24/09/2026 10:45:27".
  static String dateTimeSeconds(DateTime at) =>
      '${TimeCorrectionCopy.submittedAt(at)}:${_two(at.second)}';

  /// "alexsander vang" → "Alexsander Vang".
  static String displayName(String name) => name
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');

  /// "AV" — first letters of the first and last words.
  static String initials(String name) {
    final words = name.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) return '?';
    final first = words.first[0];
    final last = words.length > 1 ? words.last[0] : '';
    return (first + last).toUpperCase();
  }

  /// "EMP-007 • haltech"; either part may be missing.
  static String employeeLine(
    AppLocalizations l10n,
    TimeCorrectionEmployee employee,
  ) {
    final department = _isLao(l10n)
        ? employee.departmentNameLo ?? employee.departmentName
        : employee.departmentName;
    return [
      employee.employeeNumber,
      department,
    ].whereType<String>().join(' • ');
  }

  /// "4" / "4.5" hours.
  static String hours(Duration duration) {
    final hours = duration.inMinutes / 60;
    return hours == hours.roundToDouble()
        ? hours.toInt().toString()
        : hours.toStringAsFixed(1);
  }

  /// The segment's name — its Lao name under the Lao locale when there is
  /// one — capitalised: "Morning".
  static String? shiftName(AppLocalizations l10n, TimeCorrectionShift shift) {
    final name = _isLao(l10n) ? shift.nameLo ?? shift.name : shift.name;
    if (name == null) return null;
    return name[0].toUpperCase() + name.substring(1);
  }

  /// "08:00 - 12:00", or null when the segment has no hours.
  static String? shiftHours(TimeCorrectionShift shift) {
    final start = shift.start;
    final end = shift.end;
    if (start == null || end == null) return null;
    return '${TimeCorrectionCopy.hourMinuteOf(start)} - '
        '${TimeCorrectionCopy.hourMinuteOf(end)}';
  }

  /// "ເວລາວຽກປົກກະຕິ (REG - Regular Office Hours)" — the shift the segment
  /// belongs to, or null when the response has none.
  static String? shiftType(AppLocalizations l10n, TimeCorrectionShift shift) {
    final name = shift.shiftName;
    final local = _isLao(l10n) ? shift.shiftNameLo ?? name : name;
    if (local == null) return null;
    final detail = [shift.shiftCode, name].whereType<String>().join(' - ');
    return detail.isEmpty || detail == local ? local : '$local ($detail)';
  }

  static String stepRole(AppLocalizations l10n, LeaveStepRole role) =>
      switch (role) {
        LeaveStepRole.deptHead => l10n.timeCorrectionRoleDeptHead,
        LeaveStepRole.hr => l10n.timeCorrectionRoleHr,
        LeaveStepRole.unknown => l10n.timeCorrectionRoleOther,
      };

  /// A step's pill. A waiting step names the step it waits on.
  static ({String label, Color color}) stepStatus(
    AppLocalizations l10n,
    TimeCorrectionApprovalStep step,
  ) => switch (step.status) {
    LeaveStepStatus.pending => (
      label: l10n.timeCorrectionStepReviewing,
      color: AppColors.attendanceLate,
    ),
    LeaveStepStatus.approved => (
      label: l10n.timeCorrectionStepApproved,
      color: AppColors.attendancePresent,
    ),
    LeaveStepStatus.rejected => (
      label: l10n.timeCorrectionStepRejected,
      color: AppColors.danger,
    ),
    LeaveStepStatus.waiting => (
      label: l10n.timeCorrectionStepWaitingFor(step.stepNo - 1),
      color: AppColors.gray600,
    ),
  };

  /// The storage key's last segment, without the upload's `<uuid>_` prefix:
  /// `…/f9912116-…_thunjai_bill.jpg` → `thunjai_bill.jpg`.
  static String fileName(String url) {
    final path = Uri.tryParse(url)?.pathSegments.lastOrNull ?? url;
    final name = Uri.decodeComponent(path);
    final prefixed = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}_',
      caseSensitive: false,
    );
    return name.replaceFirst(prefixed, '');
  }

  /// "JPG" / "PDF", from the file name.
  static String extension(String url) {
    final name = fileName(url);
    final dot = name.lastIndexOf('.');
    return dot < 0 ? '' : name.substring(dot + 1).toUpperCase();
  }

  static bool isImage(String url) => const {
    'JPG',
    'JPEG',
    'PNG',
    'GIF',
    'WEBP',
    'HEIC',
  }.contains(extension(url));

  static String _two(int value) => value.toString().padLeft(2, '0');
}
