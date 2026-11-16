import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/payslip_lines.dart';

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
      PayslipQuantityUnit.minutes =>
        (caption.hours ?? 0) > 0
            ? l10n.payslipCaptionHoursMinutes(
                '${caption.hours}',
                '${caption.minutes ?? 0}',
              )
            : l10n.payslipCaptionMinutes('${caption.minutes ?? 0}'),
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

  static String earningsSection(AppLocalizations l10n) =>
      l10n.salaryIncomeSection;

  static String attendanceSection(AppLocalizations l10n) =>
      l10n.payslipSectionAttendance;

  static String statutorySection(AppLocalizations l10n) =>
      l10n.payslipSectionStatutory;

  static String otherDeductionsSection(AppLocalizations l10n) =>
      l10n.payslipSectionOther;
}
