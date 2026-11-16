import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/payslip.dart';

/// Turns a [Payslip]'s raw fields into the words, colour and number strings
/// the salary-history page renders. Pure functions, no widgets — same split
/// as `AttendanceHistoryCopy`.
class SalaryHistoryCopy {
  SalaryHistoryCopy._();

  static const _monthsLo = [
    'ມັງກອນ', 'ກຸມພາ', 'ມີນາ', 'ເມສາ', 'ພຶດສະພາ', 'ມິຖຸນາ',
    'ກໍລະກົດ', 'ສິງຫາ', 'ກັນຍາ', 'ຕຸລາ', 'ພະຈິກ', 'ທັນວາ',
  ];

  static const _monthsEn = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static bool _isLao(AppLocalizations l10n) => l10n.localeName.startsWith('lo');

  /// "ສິງຫາ 2026" / "August 2026" — the summary card and a payslip card's
  /// title.
  static String monthYear(AppLocalizations l10n, int month, int year) {
    final names = _isLao(l10n) ? _monthsLo : _monthsEn;
    return '${names[month - 1]} $year';
  }

  static final _amountFormat = NumberFormat('#,##0', 'en');

  /// "7,426,674" — the bare grouped number, no currency mark.
  static String amount(num value) => _amountFormat.format(value);

  /// "₭ 7,426,674".
  static String currency(num amount) => '₭ ${_amountFormat.format(amount)}';

  /// "22" / "2.5" / "0.82" — a day or hour count, with the decimals only
  /// when there are some. The stat boxes under an expanded payslip card.
  static String count(num value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toString();

  /// "20/08/2026".
  static String date(DateTime date) =>
      '${_two(date.day)}/${_two(date.month)}/${date.year}';

  static String _two(int n) => n.toString().padLeft(2, '0');

  /// A payslip line's title in the active language.
  ///
  /// The payroll API names every `lines[]` entry in English only
  /// (`component_name`: "Basic Salary", "Personal Income Tax", …) and sends
  /// no `name_lo` counterpart, so the `name`/`name_lo` pair the rest of the
  /// app leans on (`LeaveCopy.leaveTypeLabel`, `AttendanceCopy`) isn't
  /// available here. The system components are a closed set of codes
  /// instead — the same ones the mapper already switches on for glyphs — so
  /// they're translated by code, the way `FailureLocalizer` translates an
  /// error code.
  ///
  /// Anything without a known code keeps the backend's own wording: the
  /// free-text `benefits` / `deduction_items` a tenant typed in (which the
  /// API sends in Lao only), and any component this app hasn't met yet.
  static String lineTitle(AppLocalizations l10n, PayslipLine line) =>
      switch (line.code) {
        'BASIC' => l10n.salaryBaseSalary,
        'EMP-SS' => l10n.salarySocialSecurity,
        'PIT' => l10n.salaryIncomeTax,
        'LATE' => l10n.salaryComponentLate,
        'ABSENT-LATE' => l10n.salaryComponentAbsentLate,
        'EARLY-OUT' => l10n.salaryComponentEarlyOut,
        'ABSENCE' => l10n.salaryComponentAbsence,
        _ => line.title,
      };

  /// The small line under a title — "LATE · 86 ນາທີ" / "LATE · 86 minutes",
  /// "PIT · ຈາກຖານ 12,552,500", "DED · ລາຍການຫັກອື່ນໆ".
  ///
  /// The component code itself is an identifier, not prose, so it stays
  /// as-is in both languages; only the unit is translated. Lines with
  /// neither a quantity nor a base show the bare code, and the free-text
  /// benefit lines (no code, no quantity) show nothing at all.
  static String lineCaption(AppLocalizations l10n, PayslipLine line) {
    if (line.code == 'DED') {
      return 'DED · ${l10n.salaryComponentOtherDeduction}';
    }
    if (line.base > 0) {
      return '${line.code} · ${l10n.salaryPayslipLineBase(amount(line.base))}';
    }
    if (line.quantity <= 0) return line.code;

    final unit = _unitLabel(l10n, line.quantityUnit);
    final measure = '${count(line.quantity)}${unit.isEmpty ? '' : ' $unit'}';
    return line.code.isEmpty ? measure : '${line.code} · $measure';
  }

  /// `quantity_unit` off the wire, translated. An unrecognised unit is shown
  /// exactly as the backend sent it rather than dropped.
  static String _unitLabel(AppLocalizations l10n, String? unit) =>
      switch (unit) {
        null => '',
        'minutes' => l10n.salaryUnitMinutes,
        'times' => l10n.salaryUnitTimes,
        'days' => l10n.salaryUnitDays,
        'hours' => l10n.salaryUnitHours,
        _ => unit,
      };

  static String statusLabel(AppLocalizations l10n, PayslipStatus status) =>
      switch (status) {
        PayslipStatus.paid => l10n.salaryFilterPaid,
        PayslipStatus.pending => l10n.salaryFilterPending,
      };

  static Color statusColor(PayslipStatus status) => switch (status) {
    PayslipStatus.paid => AppColors.success,
    PayslipStatus.pending => AppColors.warning,
  };
}
