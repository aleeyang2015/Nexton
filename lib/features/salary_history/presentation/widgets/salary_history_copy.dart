import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/failure_localizer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/payslip_record.dart';
import '../../domain/payslip_lines.dart';
import 'salary_error_block.dart';

/// Turns a payslip's raw fields into the words, colour and number strings
/// the salary pages render. Pure functions, no widgets — same split
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
  /// when there are some, two at most (#21: 100 minutes is "1.67", not
  /// "1.6666666666666667"). The stat boxes under an expanded payslip card;
  /// the same rule as the payslip's own page ([payslipCount]).
  static String count(num value) => payslipCount(value.toDouble());

  /// "20/08/2026".
  static String date(DateTime date) =>
      '${_two(date.day)}/${_two(date.month)}/${date.year}';

  static String _two(int n) => n.toString().padLeft(2, '0');

  /// A payslip's heading: its pay month ("ຕຸລາ 2026" / "October 2026"), or
  /// just "Payslip" when the server sent no period. Never a month taken
  /// from when the payslip was made.
  static String periodTitle(AppLocalizations l10n, PayslipRecord payslip) {
    final month = payslip.periodMonth;
    final year = payslip.periodYear;
    if (month == null || year == null) return l10n.payslipDetailTitle;
    return monthYear(l10n, month, year);
  }

  /// "ຈ່າຍວັນທີ 05/11/2026" once the money was paid, else nothing. The date
  /// is the server's `paid_at`; there is no stand-in for it. A payment that
  /// failed has no "paid on", whatever date came with it.
  static String? paidOn(AppLocalizations l10n, PayslipRecord payslip) {
    final paidAt = payslip.paidAt;
    if (paidAt == null || isPaymentFailed(payslip)) return null;
    return '${l10n.salaryPaidOnLabel} ${date(paidAt)}';
  }

  /// True when the money did not reach the employee: they should contact HR.
  static bool isPaymentFailed(PayslipRecord payslip) =>
      payslip.paymentStatus == PayslipPaymentStatus.failed;

  /// What the payslip page's header shows, taken from the list's row so the
  /// two screens say the same thing: the title with the pay month, the line
  /// under it (paid on, or the status) and the status pill.
  static ({
    String title,
    String subtitle,
    Color color,
    String? pill,
    bool failed,
  })
  detailHeader(AppLocalizations l10n, PayslipRecord row) {
    final status = recordStatus(l10n, row);
    final hasPeriod = row.periodMonth != null && row.periodYear != null;

    return (
      title: hasPeriod
          ? '${l10n.payslipDetailTitle} – ${periodTitle(l10n, row)}'
          : l10n.payslipDetailTitle,
      subtitle: paidOn(l10n, row) ?? status?.label ?? '',
      color: status?.color ?? AppColors.subTitle,
      pill: status?.label,
      failed: isPaymentFailed(row),
    );
  }

  /// What the status pill says for a payslip, or null when there is nothing
  /// the App can truthfully say.
  ///
  /// A payment that failed says so, in red, whatever the run's status: that
  /// is what the employee needs to know. Otherwise the run is Approved (the
  /// money has not been sent yet) or Paid. There is no "Pending": staff are
  /// never given a payslip in any other state, and a status the App does not
  /// know gets no pill rather than a guess.
  static ({String label, Color color})? recordStatus(
    AppLocalizations l10n,
    PayslipRecord payslip,
  ) {
    if (isPaymentFailed(payslip)) {
      return (label: l10n.salaryPaymentFailed, color: AppColors.danger);
    }
    return switch (payslip.status) {
      PayslipRunStatus.paid => (
        label: l10n.salaryFilterPaid,
        color: AppColors.success,
      ),
      PayslipRunStatus.approved => (
        label: l10n.salaryStatusApproved,
        color: AppColors.info,
      ),
      PayslipRunStatus.unknown => null,
    };
  }

  /// The top card's title: "ເງິນເດືອນສຸດທິ • ທັນວາ 2026", from the
  /// payslip's month and year (never the server's English `period_label`).
  static String latestTitle(AppLocalizations l10n, PayslipLatest latest) =>
      '${l10n.salaryNetSalaryLabel} • '
      '${monthYear(l10n, latest.month, latest.year)}';

  /// The top card's small line: "ລາຍຮັບລວມ ₭ 12,800,000 · ຫັກລວມ ₭ 5,373,326".
  /// The server's figures, nothing worked out.
  static String latestTotals(AppLocalizations l10n, PayslipLatest latest) =>
      '${l10n.salaryGrossLabel} ${currency(latest.grossPay)} · '
      '${l10n.salaryTotalDeductionsLabel} ${currency(latest.totalDeductions)}';

  /// What the PDF page says when the PDF could not be had, and whether
  /// Retry is offered:
  ///
  /// * not there (404) → #23's "not available", no Retry;
  /// * no payroll (403 `MODULE_NOT_ACTIVE`) → its own text, no Retry;
  /// * no signal or a timeout → that, with Retry;
  /// * anything else (500, a 200 that is not a PDF) → "could not make the
  ///   PDF, please try again", with Retry.
  static ({String message, bool canRetry}) pdfError(
    AppLocalizations l10n,
    Object? error,
  ) {
    if (SalaryErrorBlock.isNotFound(error)) {
      return (message: l10n.payslipNotAvailable, canRetry: false);
    }
    if (SalaryErrorBlock.isModuleOff(error) && error is Failure) {
      return (message: error.localize(l10n), canRetry: false);
    }
    if (error is NetworkFailure && error.statusCode == null) {
      return (message: error.localize(l10n), canRetry: true);
    }
    return (message: l10n.payslipPdfMakeFailed, canRetry: true);
  }
}
