import '../../domain/entities/payslip.dart';

/// Reads one payslip object as `GET /payroll/payslips/my` (list rows) and
/// `GET /payroll/payslips/my/{id}` (the same row plus `lines`, `benefits` and
/// `deduction_items`) return it.
///
/// Totals (`total_earnings`, `total_deductions`, `net_salary`) are taken from
/// the wire as-is — the backend is the only place they're computed. The
/// itemised sections are split by each line's `type` / `category`; the
/// component code only ever picks the glyph.
class PayslipModel {
  const PayslipModel._();

  static const _paid = 'paid';
  static const _earning = 'earning';
  static const _deduction = 'deduction';
  static const _penalty = 'penalty';

  static Payslip fromJson(Map<String, dynamic> json) {
    // No explicit payroll period on the wire — the run's creation instant is
    // the closest thing to "which month this is".
    final period = _dateTime(json['created_at']) ?? DateTime.now();

    final lines = _objects(json['lines'])
      ..sort((a, b) => (_int(a['sort_order']) ?? 0).compareTo(_int(b['sort_order']) ?? 0));

    final earnings = <PayslipLine>[];
    final attendanceDeductions = <PayslipLine>[];
    final statutoryDeductions = <PayslipLine>[];

    for (final line in lines) {
      final type = _string(line['type']);
      if (type == _earning) {
        earnings.add(_line(line, sign: 1));
      } else if (type == _deduction) {
        final penalty = _string(line['category']) == _penalty;
        (penalty ? attendanceDeductions : statutoryDeductions).add(
          _line(line, sign: -1, icon: _iconFor(_string(line['component_code']))),
        );
      }
      // Any other `type` is not a payslip line the app knows how to print.
    }

    final allowances = [
      for (final benefit in _objects(json['benefits']))
        PayslipLine(
          title: _string(benefit['name']) ?? '',
          amount: _double(benefit['amount']) ?? 0,
        ),
    ];

    // Ad-hoc deductions ride in the "Statutory / Other" section, after the
    // statutory lines.
    for (final item in _objects(json['deduction_items'])) {
      statutoryDeductions.add(
        PayslipLine(
          title: _string(item['deduction_name']) ?? '',
          amount: -(_double(item['amount']) ?? 0),
          icon: PayslipLineIcon.otherDeduction,
        ),
      );
    }

    return Payslip(
      id: _string(json['id']) ?? '',
      year: period.year,
      month: period.month,
      status: _string(json['payment_status']) == _paid
          ? PayslipStatus.paid
          : PayslipStatus.pending,
      payrollStatus: _string(json['status']) ?? '',
      employeeName: (_string(json['employee_name']) ?? '').trim(),
      employeeCode: (_string(json['employee_number']) ?? '').trim(),
      position: (_string(json['position_title']) ?? '').trim(),
      department: (_string(json['department_name']) ?? '').trim(),
      baseSalary: _double(json['base_salary']) ?? 0,
      grossSalary: _double(json['total_earnings']) ?? 0,
      totalDeductions: _double(json['total_deductions']) ?? 0,
      netSalary: _double(json['net_salary']) ?? 0,
      socialSecurity: _double(json['employee_ss']) ?? 0,
      employerSocialSecurity: _double(json['employer_ss']) ?? 0,
      incomeTax: _double(json['income_tax']) ?? 0,
      workingDays: _double(json['work_days']) ?? 0,
      overtimeHours: _double(json['overtime_hours']) ?? 0,
      unpaidLeaveDays: _double(json['unpaid_leave_days']) ?? 0,
      earnings: earnings,
      allowances: allowances,
      attendanceDeductions: attendanceDeductions,
      statutoryDeductions: statutoryDeductions,
      taxableIncome: _double(json['taxable_income']) ?? 0,
    );
  }

  /// One `lines[]` entry, passed through as raw wire values — the code, the
  /// quantity it was charged on and the English `component_name`. Turning
  /// those into the title and "LATE · 86 ນາທີ" caption the detail page shows
  /// is `SalaryHistoryCopy`'s job, because it depends on the active locale.
  static PayslipLine _line(
    Map<String, dynamic> line, {
    required int sign,
    PayslipLineIcon icon = PayslipLineIcon.none,
  }) {
    final code = _string(line['component_code']) ?? '';

    return PayslipLine(
      code: code,
      title: _string(line['component_name']) ?? code,
      quantity: _double(line['quantity']) ?? 0,
      quantityUnit: _string(line['quantity_unit']),
      amount: sign * (_double(line['amount']) ?? 0),
      icon: icon,
    );
  }

  /// Glyph for a deduction line, by its component code. Codes the app
  /// doesn't recognise still render, with the generic deduction glyph.
  static PayslipLineIcon _iconFor(String? code) => switch (code) {
    'LATE' => PayslipLineIcon.lateArrival,
    'ABSENT-LATE' => PayslipLineIcon.absentLate,
    'EARLY-OUT' => PayslipLineIcon.earlyOut,
    'ABSENCE' => PayslipLineIcon.absence,
    'EMP-SS' => PayslipLineIcon.socialSecurity,
    'PIT' => PayslipLineIcon.incomeTax,
    _ => PayslipLineIcon.otherDeduction,
  };

  static String? _string(dynamic value) => value is String ? value : null;

  static double? _double(dynamic value) => (value as num?)?.toDouble();

  static int? _int(dynamic value) => (value as num?)?.toInt();

  /// An instant (`created_at`): UTC or offset in, local out.
  static DateTime? _dateTime(dynamic value) {
    final text = _string(value);
    if (text == null || text.isEmpty) return null;
    return DateTime.tryParse(text)?.toLocal();
  }

  static List<Map<String, dynamic>> _objects(dynamic value) {
    if (value is! List) return [];
    return value.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }
}
