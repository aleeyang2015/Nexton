import 'package:equatable/equatable.dart';

/// Whether a month's payslip has been paid out yet.
enum PayslipStatus { paid, pending }

/// Which leading glyph the payslip-detail page draws next to a line — only
/// the deduction sections use one; earnings render without an icon.
enum PayslipLineIcon {
  none,
  lateArrival,
  absentLate,
  earlyOut,
  absence,
  socialSecurity,
  incomeTax,
  otherDeduction,
}

/// One printed line on a payslip — a single earning or a single deduction,
/// with the code/context caption the detail page shows beneath its title
/// (e.g. "LATE · 33 min × ₭12,480"). [amount] is signed: positive for an
/// earning, negative for a deduction.
class PayslipLine extends Equatable {
  final String title;
  final String caption;
  final double amount;
  final PayslipLineIcon icon;

  const PayslipLine({
    required this.title,
    required this.caption,
    required this.amount,
    this.icon = PayslipLineIcon.none,
  });

  @override
  List<Object?> get props => [title, caption, amount, icon];
}

/// One month's payslip — the salary-history page's list item and, expanded,
/// its earnings/deductions breakdown. The itemised [earnings] / [allowances]
/// / [attendanceDeductions] / [statutoryDeductions] lists back the full
/// payslip-detail page; the aggregate fields below stay the source of truth
/// for the history page's inline summary and the totals strip.
class Payslip extends Equatable {
  final String id;
  final int year;

  /// 1-12.
  final int month;

  /// Null while [status] is [PayslipStatus.pending] — nothing has been paid
  /// out yet.
  final DateTime? paidDate;
  final PayslipStatus status;

  final String employeeName;
  final String employeeCode;
  final String position;

  /// Optional — shown as the third segment of the detail page's identity
  /// line when set.
  final String department;

  final double baseSalary;
  final double allowance;

  final double socialSecurity;

  /// e.g. `0.045` for the "(4.5%)" the social-security row shows.
  final double socialSecurityRate;
  final double incomeTax;
  final double otherDeductions;

  final int workingDays;
  final double overtimeHours;
  final int paidLeaveDays;

  /// Detail-page sections. Empty on payslips that only feed the history
  /// list; the detail page renders whatever is present.
  final List<PayslipLine> earnings;
  final List<PayslipLine> allowances;
  final List<PayslipLine> attendanceDeductions;
  final List<PayslipLine> statutoryDeductions;

  /// Detail-page footer figures.
  final double taxableIncome;
  final double socialSecurityBase;

  const Payslip({
    required this.id,
    required this.year,
    required this.month,
    this.paidDate,
    required this.status,
    required this.employeeName,
    required this.employeeCode,
    required this.position,
    this.department = '',
    required this.baseSalary,
    required this.allowance,
    required this.socialSecurity,
    required this.socialSecurityRate,
    required this.incomeTax,
    required this.otherDeductions,
    required this.workingDays,
    required this.overtimeHours,
    required this.paidLeaveDays,
    this.earnings = const [],
    this.allowances = const [],
    this.attendanceDeductions = const [],
    this.statutoryDeductions = const [],
    this.taxableIncome = 0,
    this.socialSecurityBase = 0,
  });

  double get grossSalary => baseSalary + allowance;

  double get totalDeductions => socialSecurity + incomeTax + otherDeductions;

  double get netSalary => grossSalary - totalDeductions;

  @override
  List<Object?> get props => [
    id,
    year,
    month,
    paidDate,
    status,
    employeeName,
    employeeCode,
    position,
    department,
    baseSalary,
    allowance,
    socialSecurity,
    socialSecurityRate,
    incomeTax,
    otherDeductions,
    workingDays,
    overtimeHours,
    paidLeaveDays,
    earnings,
    allowances,
    attendanceDeductions,
    statutoryDeductions,
    taxableIncome,
    socialSecurityBase,
  ];
}
