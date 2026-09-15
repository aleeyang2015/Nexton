import 'package:equatable/equatable.dart';

/// Whether a month's payslip has been paid out yet — the wire
/// `payment_status`. Anything the backend doesn't call `paid` is pending.
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
/// (e.g. "LATE · 86 minutes"). [amount] is signed: positive for an
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
/// payslip-detail page and only arrive with `GET /payroll/payslips/my/{id}`;
/// the aggregate fields below come straight from the backend on both the
/// list and the detail call and stay the source of truth for the history
/// page's inline summary and the totals strip.
class Payslip extends Equatable {
  final String id;

  /// Payroll period. The API carries no explicit period field, so the data
  /// layer derives these from the payslip's `created_at`.
  final int year;

  /// 1-12.
  final int month;

  /// The API does not report a payment date yet; always null for now.
  final DateTime? paidDate;

  /// `payment_status` — what the Paid/Pending chips and pills reflect.
  final PayslipStatus status;

  /// `status` — the payroll *processing* state (`calculated`, …), distinct
  /// from [status]. Not rendered anywhere yet; kept so it's available.
  final String payrollStatus;

  final String employeeName;
  final String employeeCode;
  final String position;

  /// Optional — shown as the third segment of the detail page's identity
  /// line when set.
  final String department;

  final double baseSalary;

  /// `total_earnings` — base salary plus every benefit/allowance. Backend
  /// value, never recomputed here.
  final double grossSalary;

  /// `total_deductions` — every penalty, statutory and other deduction.
  /// Backend value, never recomputed here.
  final double totalDeductions;

  /// `net_salary`. Backend value, never recomputed here.
  final double netSalary;

  /// `employee_ss` — the employee's own social-security deduction.
  final double socialSecurity;

  /// `employer_ss` — the employer's contribution. Not a deduction from the
  /// employee and not rendered; kept so it's available.
  final double employerSocialSecurity;

  /// e.g. `0.045` for the "(4.5%)" the social-security row shows; `0` when
  /// the backend doesn't report a rate, in which case the row omits it.
  final double socialSecurityRate;
  final double incomeTax;

  final double workingDays;
  final double overtimeHours;
  final double unpaidLeaveDays;

  /// Detail-page sections. Empty on payslips that only feed the history
  /// list; the detail page renders whatever is present.
  final List<PayslipLine> earnings;
  final List<PayslipLine> allowances;
  final List<PayslipLine> attendanceDeductions;
  final List<PayslipLine> statutoryDeductions;

  /// Detail-page footer figures. [socialSecurityBase] is `0` when the
  /// backend doesn't report it, and the footer skips the row.
  final double taxableIncome;
  final double socialSecurityBase;

  const Payslip({
    required this.id,
    required this.year,
    required this.month,
    this.paidDate,
    required this.status,
    this.payrollStatus = '',
    required this.employeeName,
    required this.employeeCode,
    required this.position,
    this.department = '',
    required this.baseSalary,
    required this.grossSalary,
    required this.totalDeductions,
    required this.netSalary,
    required this.socialSecurity,
    this.employerSocialSecurity = 0,
    this.socialSecurityRate = 0,
    required this.incomeTax,
    required this.workingDays,
    required this.overtimeHours,
    required this.unpaidLeaveDays,
    this.earnings = const [],
    this.allowances = const [],
    this.attendanceDeductions = const [],
    this.statutoryDeductions = const [],
    this.taxableIncome = 0,
    this.socialSecurityBase = 0,
  });

  /// Everything earned on top of the base salary (benefits, allowances) —
  /// the history card's "Allowance / Others" row. The backend reports only
  /// the total, so this is the remainder of [grossSalary].
  double get allowance => grossSalary - baseSalary;

  /// Every deduction that is neither social security nor income tax
  /// (attendance penalties, other deduction items) — the history card's
  /// "Other Deductions" row. The remainder of [totalDeductions].
  double get otherDeductions => totalDeductions - socialSecurity - incomeTax;

  @override
  List<Object?> get props => [
    id,
    year,
    month,
    paidDate,
    status,
    payrollStatus,
    employeeName,
    employeeCode,
    position,
    department,
    baseSalary,
    grossSalary,
    totalDeductions,
    netSalary,
    socialSecurity,
    employerSocialSecurity,
    socialSecurityRate,
    incomeTax,
    workingDays,
    overtimeHours,
    unpaidLeaveDays,
    earnings,
    allowances,
    attendanceDeductions,
    statutoryDeductions,
    taxableIncome,
    socialSecurityBase,
  ];
}
