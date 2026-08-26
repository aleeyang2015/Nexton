import '../../domain/entities/payslip.dart';

abstract class SalaryRemoteDataSource {
  Future<List<Payslip>> history(int year);
}

/// Stand-in for the payroll endpoints, which don't exist yet — returns fixed
/// sample data after a short delay so the UI has something real to render.
/// Swap the body below for a Dio call once the API is available; the
/// repository and everything above it never has to change.
class SalaryRemoteDataSourceImpl implements SalaryRemoteDataSource {
  static const _employeeName = 'Sandy Vang';
  static const _employeeCode = 'EMP-002';
  static const _position = 'IT Developer';
  static const _baseSalary = 12000000.0;
  static const _allowance = 800000.0;
  static const _socialSecurityRate = 0.045;

  static final _payslips = <Payslip>[
    // Not yet processed — demonstrates the "ລໍຖ້າ" (pending) filter.
    Payslip(
      id: '2026-09',
      year: 2026,
      month: 9,
      status: PayslipStatus.pending,
      employeeName: _employeeName,
      employeeCode: _employeeCode,
      position: _position,
      baseSalary: _baseSalary,
      allowance: _allowance,
      socialSecurity: 247500,
      socialSecurityRate: _socialSecurityRate,
      incomeTax: 900000,
      otherDeductions: 4000000,
      workingDays: 18,
      overtimeHours: 0,
      paidLeaveDays: 0,
    ),
    Payslip(
      id: '2026-08',
      year: 2026,
      month: 8,
      paidDate: DateTime(2026, 8, 20),
      status: PayslipStatus.paid,
      employeeName: _employeeName,
      employeeCode: _employeeCode,
      position: _position,
      baseSalary: _baseSalary,
      allowance: _allowance,
      socialSecurity: 247500,
      socialSecurityRate: _socialSecurityRate,
      incomeTax: 940249,
      otherDeductions: 4185577,
      workingDays: 22,
      overtimeHours: 0,
      paidLeaveDays: 0,
    ),
    Payslip(
      id: '2026-07',
      year: 2026,
      month: 7,
      paidDate: DateTime(2026, 7, 20),
      status: PayslipStatus.paid,
      employeeName: _employeeName,
      employeeCode: _employeeCode,
      position: _position,
      baseSalary: _baseSalary,
      allowance: _allowance,
      socialSecurity: 247500,
      socialSecurityRate: _socialSecurityRate,
      incomeTax: 900000,
      otherDeductions: 3901974,
      workingDays: 23,
      overtimeHours: 0,
      paidLeaveDays: 1,
    ),
    Payslip(
      id: '2026-06',
      year: 2026,
      month: 6,
      paidDate: DateTime(2026, 6, 19),
      status: PayslipStatus.paid,
      employeeName: _employeeName,
      employeeCode: _employeeCode,
      position: _position,
      baseSalary: _baseSalary,
      allowance: _allowance,
      socialSecurity: 247500,
      socialSecurityRate: _socialSecurityRate,
      incomeTax: 875000,
      otherDeductions: 3750000,
      workingDays: 21,
      overtimeHours: 2.5,
      paidLeaveDays: 0,
    ),
    Payslip(
      id: '2026-05',
      year: 2026,
      month: 5,
      paidDate: DateTime(2026, 5, 20),
      status: PayslipStatus.paid,
      employeeName: _employeeName,
      employeeCode: _employeeCode,
      position: _position,
      baseSalary: _baseSalary,
      allowance: _allowance,
      socialSecurity: 247500,
      socialSecurityRate: _socialSecurityRate,
      incomeTax: 860000,
      otherDeductions: 3600000,
      workingDays: 22,
      overtimeHours: 0,
      paidLeaveDays: 0,
    ),
    Payslip(
      id: '2026-04',
      year: 2026,
      month: 4,
      paidDate: DateTime(2026, 4, 20),
      status: PayslipStatus.paid,
      employeeName: _employeeName,
      employeeCode: _employeeCode,
      position: _position,
      baseSalary: _baseSalary,
      allowance: _allowance,
      socialSecurity: 247500,
      socialSecurityRate: _socialSecurityRate,
      incomeTax: 845000,
      otherDeductions: 3450000,
      workingDays: 22,
      overtimeHours: 0,
      paidLeaveDays: 0,
    ),
  ];

  @override
  Future<List<Payslip>> history(int year) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final records = _payslips.where((p) => p.year == year).toList()
      ..sort((a, b) => b.month.compareTo(a.month));
    return records;
  }
}
