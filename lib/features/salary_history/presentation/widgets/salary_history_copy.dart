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

  /// "₭ 7,426,674".
  static String currency(num amount) => '₭ ${_amountFormat.format(amount)}';

  /// "20/08/2026".
  static String date(DateTime date) =>
      '${_two(date.day)}/${_two(date.month)}/${date.year}';

  static String _two(int n) => n.toString().padLeft(2, '0');

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
