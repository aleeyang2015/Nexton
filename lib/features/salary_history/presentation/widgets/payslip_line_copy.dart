import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/payslip_lines.dart';
// The domain's `caption` again, by a prefix: inside [PayslipLineCopy] the
// bare name is the class's own `caption`.
import '../../domain/payslip_lines.dart' as domain show caption;

/// What a row's amount is, for the page to colour it.
enum PayslipAmountKind { zero, earning, deduction, plain }

/// Puts the rows `groupLines` makes into the user's language: a row's
/// title, its caption, and the four section names.
///
/// Words only. Which group a line belongs to, what its amount is and how a
/// count is split into hours and minutes are decided in
/// `domain/payslip_lines.dart`.
class PayslipLineCopy {
  PayslipLineCopy._();

  /// The row's title: the App's own name for a line it knows, else the name
  /// the server sent (a company's own allowance, a benefit, a deduction
  /// item).
  static String title(AppLocalizations l10n, PayslipRow row) =>
      switch (row.title) {
        PayslipLineTitle.basic => l10n.salaryBaseSalary,
        PayslipLineTitle.overtime => l10n.payslipLineOvertime,
        PayslipLineTitle.late => l10n.payslipLineLate,
        PayslipLineTitle.absentLate => l10n.payslipLineAbsentLate,
        PayslipLineTitle.earlyOut => l10n.payslipLineEarlyOut,
        PayslipLineTitle.missedPart => l10n.payslipLineMissedPart,
        PayslipLineTitle.absence => l10n.payslipLineAbsence,
        PayslipLineTitle.unpaidLeave => l10n.payslipLineUnpaidLeave,
        PayslipLineTitle.attendanceSettlement =>
          l10n.payslipLineAttendanceSettlement,
        PayslipLineTitle.loan => l10n.payslipLineLoan,
        PayslipLineTitle.socialSecurity => l10n.salarySocialSecurity,
        PayslipLineTitle.incomeTax => l10n.salaryIncomeTax,
        null => row.name,
      };

  /// The small line under the title, or null when the row has none:
  /// "1 ຊມ 35 ນາທີ", "0 ນາທີ", "0.5 ວັນ", "2 ເທື່ອ", a loan's own name.
  static String? caption(AppLocalizations l10n, PayslipRow row) {
    final caption = row.caption;
    if (caption == null) return null;

    final number = caption.number ?? '';
    final text = switch (caption.unit) {
      PayslipQuantityUnit.minutes => _hoursMinutes(
        l10n,
        caption.hours ?? 0,
        caption.minutes ?? 0,
      ),
      PayslipQuantityUnit.times => l10n.payslipCaptionTimes(number),
      PayslipQuantityUnit.days => l10n.payslipCaptionDays(number),
      PayslipQuantityUnit.hours => l10n.payslipCaptionHours(number),
      // A unit the App has no word for: the number, with the server's.
      PayslipQuantityUnit.other => '$number ${caption.text ?? ''}'.trim(),
      null => caption.text ?? '',
    };
    // Nothing to say is no caption, not an empty line.
    return text.trim().isEmpty ? null : text;
  }

  /// A count of minutes as the payslip writes it: "2 ຊມ 0 ນາທີ" for 120,
  /// "45 ນາທີ" for 45, "0 ນາທີ" for 0. The split is the domain's [domain.caption].
  static String minutes(AppLocalizations l10n, int minutes) {
    final split = domain.caption(minutes.toDouble(), 'minutes')!;
    return _hoursMinutes(l10n, split.hours ?? 0, split.minutes ?? 0);
  }

  static String _hoursMinutes(AppLocalizations l10n, int hours, int minutes) =>
      hours > 0
      ? l10n.payslipCaptionHoursMinutes('$hours', '$minutes')
      : l10n.payslipCaptionMinutes('$minutes');

  /// How a row's amount is written, and what it is.
  ///
  /// * zero → "0", shown and not hidden;
  /// * an earning → "+ 162,259"; a deduction → "- 68,910";
  /// * a row the App could not place ([unplaced]), or an amount below zero
  ///   (not something the server sends) → the number as it is, with no sign
  ///   put in front: the App does not say which way it counts.
  ///
  /// The number is the row's own; nothing is worked out.
  static ({String text, PayslipAmountKind kind}) amount(
    PayslipRow row, {
    bool unplaced = false,
  }) {
    final number = _grouped.format(row.amount);
    if (row.amount == 0) return (text: number, kind: PayslipAmountKind.zero);
    if (unplaced || row.amount < 0) {
      return (text: number, kind: PayslipAmountKind.plain);
    }
    return row.isDeduction
        ? (text: '- $number', kind: PayslipAmountKind.deduction)
        : (text: '+ $number', kind: PayslipAmountKind.earning);
  }

  static final _grouped = NumberFormat('#,##0', 'en');

  static String earningsSection(AppLocalizations l10n) =>
      l10n.salaryIncomeSection;

  static String attendanceSection(AppLocalizations l10n) =>
      l10n.payslipSectionAttendance;

  static String statutorySection(AppLocalizations l10n) =>
      l10n.payslipSectionStatutory;

  static String otherDeductionsSection(AppLocalizations l10n) =>
      l10n.payslipSectionOther;
}
