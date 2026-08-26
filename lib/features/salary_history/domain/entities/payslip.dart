import 'package:equatable/equatable.dart';

/// Whether a month's payslip has been paid out yet.
enum PayslipStatus { paid, pending }

/// One month's payslip — the salary-history page's list item and, expanded,
/// its earnings/deductions breakdown.
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

  const Payslip({
    required this.id,
    required this.year,
    required this.month,
    this.paidDate,
    required this.status,
    required this.employeeName,
    required this.employeeCode,
    required this.position,
    required this.baseSalary,
    required this.allowance,
    required this.socialSecurity,
    required this.socialSecurityRate,
    required this.incomeTax,
    required this.otherDeductions,
    required this.workingDays,
    required this.overtimeHours,
    required this.paidLeaveDays,
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
    baseSalary,
    allowance,
    socialSecurity,
    socialSecurityRate,
    incomeTax,
    otherDeductions,
    workingDays,
    overtimeHours,
    paidLeaveDays,
  ];
}
