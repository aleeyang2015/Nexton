import 'package:flutter/material.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/failure_localizer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../core/utils/ot_pay.dart';
import '../../domain/entities/ot_piece.dart';
import '../../domain/entities/ot_request.dart';
import '../../domain/entities/ot_step.dart';

/// Turns OT fields into the words and colours the OT screens show. Pure
/// functions, no widgets: same split as `LeaveCopy`.
class OtCopy {
  OtCopy._();

  static const _monthsLo = [
    'ມັງກອນ', 'ກຸມພາ', 'ມີນາ', 'ເມສາ', 'ພຶດສະພາ', 'ມິຖຸນາ',
    'ກໍລະກົດ', 'ສິງຫາ', 'ກັນຍາ', 'ຕຸລາ', 'ພະຈິກ', 'ທັນວາ',
  ];

  static const _monthsEn = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static const _monthsShortLo = [
    'ມ.ກ.', 'ກ.ພ.', 'ມ.ນ.', 'ມ.ສ.', 'ພ.ພ.', 'ມິ.ຖ.',
    'ກ.ລ.', 'ສ.ຫ.', 'ກ.ຍ.', 'ຕ.ລ.', 'ພ.ຈ.', 'ທ.ວ.',
  ];

  static const _monthsShortEn = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static bool _isLao(AppLocalizations l10n) => l10n.localeName.startsWith('lo');

  /// The status pill, in the leave wording; null for a status the App does
  /// not know (no pill rather than a guess).
  static ({String label, Color color})? statusPill(
    AppLocalizations l10n,
    OtStatus status,
  ) => switch (status) {
    OtStatus.pending => (
      label: l10n.leaveStatusPending,
      color: AppColors.primary,
    ),
    OtStatus.approved => (
      label: l10n.leaveStatusApproved,
      color: AppColors.success,
    ),
    OtStatus.rejected => (
      label: l10n.leaveStatusRejected,
      color: AppColors.danger,
    ),
    OtStatus.cancelled => (
      label: l10n.leaveStatusCancelled,
      color: AppColors.gray500,
    ),
    OtStatus.unknown => null,
  };

  /// "18:00–20:00": the company's times as sent; "22:00–02:00 (ມື້ຖັດໄປ)"
  /// when it ends the next day. A missing time leaves no stray dash.
  static String window(AppLocalizations l10n, OtRequest request) {
    final times = [
      request.startTime,
      request.endTime,
    ].where((t) => t.isNotEmpty).join('–');
    if (times.isEmpty || !request.endsNextDay) return times;
    return '$times ${l10n.otNextDay}';
  }

  /// "14/11/2026".
  static String date(DateTime day) =>
      '${_two(day.day)}/${_two(day.month)}/${day.year}';

  /// The month filter's label: "ທຸກເດືອນ" for none, else "ພະຈິກ 2026".
  static String monthLabel(AppLocalizations l10n, DateTime? month) {
    if (month == null) return l10n.otAllMonths;
    final names = _isLao(l10n) ? _monthsLo : _monthsEn;
    return '${names[month.month - 1]} ${month.year}';
  }

  /// A month's short name for the picker: "ມ.ກ." / "Jan". [month] is 1-12.
  static String shortMonth(AppLocalizations l10n, int month) =>
      (_isLao(l10n) ? _monthsShortLo : _monthsShortEn)[month - 1];

  /// "ລໍຖ້າ: ຫົວໜ້າ" / "ລໍຖ້າ: ຝ່າຍບຸກຄະລາກອນ": who the request waits for,
  /// from the step waiting now. Null unless the request is pending and a
  /// step of a known role is waiting.
  static String? waitingFor(AppLocalizations l10n, OtRequest request) {
    if (request.status != OtStatus.pending) return null;
    final role = switch (request.pendingStep?.role) {
      OtStepRole.deptHead => l10n.leaveStepDeptHead,
      OtStepRole.hr => l10n.leaveStepHr,
      OtStepRole.unknown || null => null,
    };
    return role == null ? null : l10n.otWaitingFor(role);
  }

  /// "08:00–12:00 · 200%": a piece's window on the phone's clock and its
  /// pay. A part the server did not send is left out.
  static String piece(AppLocalizations l10n, OtPiece piece) {
    final start = piece.startsAt;
    final end = piece.endsAt;
    final window = [
      if (start != null) _hhmm(start),
      if (end != null) _hhmm(end),
    ].join('–');
    final value = piece.payValue;
    final pay = value == null ? null : otPayLabel(l10n, piece.payType, value);
    return [window, if (pay != null) pay].where((p) => p.isNotEmpty).join(' · ');
  }

  /// The notes the request carries, each only when its field says so: did
  /// not come, paid in cash, a leave day (HR decides), from an HR post.
  static List<String> notes(AppLocalizations l10n, OtRequest request) => [
    if (request.didNotCome) l10n.otNoteDidNotCome,
    if (request.paidByHandAt != null) l10n.otNotePaidByHand,
    if (request.hrOnly) l10n.otNoteHrOnly,
    if (request.announcementId != null) l10n.otNoteFromPost,
  ];

  static String _hhmm(DateTime time) {
    final local = time.toLocal();
    return '${_two(local.hour)}:${_two(local.minute)}';
  }

  /// What the OT list says when it could not load, and whether Retry is
  /// offered:
  /// * a refusal (`400`, `403`, `422`: no employee linked, no module, a bad
  ///   filter) → its own text, no Retry: asking again cannot change it;
  /// * anything else (no signal, a server error) → "could not load OT", with
  ///   Retry.
  static ({String message, bool canRetry}) listError(
    AppLocalizations l10n,
    Object? error,
  ) {
    if (error is ValidationFailure) {
      return (message: error.localize(l10n), canRetry: false);
    }
    return (message: l10n.otListLoadFailed, canRetry: true);
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}
