import '../../domain/entities/payslip_record.dart';

/// Reads a `PayslipResponse` (`GET /payroll/payslips/my` and `/my/:id`) into
/// a [PayslipRecord], changing nothing on the way.
///
/// * Money (`int64` on the server) is read as whole kip.
/// * The three counts are read as they are: `0.5` stays `0.5`.
/// * `benefits[].amount` and `deduction_items[].amount` keep their decimals.
/// * A list the server left out is an empty list; a list row has no `lines`.
/// * A `status` or `payment_status` the App does not know is `unknown`.
/// * The period comes from `period_year` / `period_month` only. It is never
///   taken from `created_at`.
///
/// Nothing here adds, subtracts or rounds. A body with no `id` is not a
/// payslip and throws a [FormatException].
class PayslipRecordModel {
  const PayslipRecordModel._();

  static PayslipRecord fromJson(Map<String, dynamic> json) {
    // Every payslip has an id. A body without one is not a payslip (an
    // envelope read as its own payload, say), and is refused rather than
    // shown as a payslip of zero kip.
    final id = _text(json['id']);
    if (id.isEmpty) {
      throw const FormatException('A payslip without an id');
    }

    return PayslipRecord(
      id: id,
      payrollRunId: _text(json['payroll_run_id']),
      employeeId: _text(json['employee_id']),
      employeeNumber: _text(json['employee_number']),
      employeeName: _text(json['employee_name']),
      departmentName: _textOrNull(json['department_name']),
      positionTitle: _textOrNull(json['position_title']),
      baseSalary: _kip(json['base_salary']),
      totalEarnings: _kip(json['total_earnings']),
      totalDeductions: _kip(json['total_deductions']),
      netSalary: _kip(json['net_salary']),
      employeeSs: _kip(json['employee_ss']),
      employerSs: _kip(json['employer_ss']),
      taxableIncome: _kip(json['taxable_income']),
      incomeTax: _kip(json['income_tax']),
      workDays: _count(json['work_days']),
      overtimeHours: _count(json['overtime_hours']),
      unpaidLeaveDays: _count(json['unpaid_leave_days']),
      paymentStatus: _paymentStatus(json['payment_status']),
      status: _runStatus(json['status']),
      periodYear: _wholeOrNull(json['period_year']),
      periodMonth: _month(json['period_month']),
      paidAt: _instant(json['paid_at']),
      lines: _objects(json['lines']).map(_line).toList(),
      benefits: _objects(json['benefits']).map(_benefit).toList(),
      deductionItems: _objects(
        json['deduction_items'],
      ).map(_deductionItem).toList(),
      overtimeItems: _objects(
        json['overtime_items'],
      ).map(_overtimeItem).toList(),
      createdAt: _instant(json['created_at']),
      updatedAt: _instant(json['updated_at']),
    );
  }

  static PayslipRecordLine _line(Map<String, dynamic> json) {
    return PayslipRecordLine(
      id: _text(json['id']),
      componentCode: _text(json['component_code']),
      componentName: _text(json['component_name']),
      type: switch (json['type']) {
        'earning' => PayslipLineType.earning,
        'deduction' => PayslipLineType.deduction,
        _ => PayslipLineType.unknown,
      },
      category: _text(json['category']),
      amount: _kip(json['amount']),
      isTaxable: json['is_taxable'] == true,
      sortOrder: _wholeOrNull(json['sort_order']) ?? 0,
      quantity: _count(json['quantity']),
      quantityUnit: _textOrNull(json['quantity_unit']),
      ratePer: _kip(json['rate_per']),
      rateAmount: _kip(json['rate_amount']),
    );
  }

  static PayslipBenefit _benefit(Map<String, dynamic> json) => PayslipBenefit(
    id: _text(json['id']),
    name: _text(json['name']),
    amount: _count(json['amount']),
  );

  static PayslipDeductionItem _deductionItem(Map<String, dynamic> json) =>
      PayslipDeductionItem(
        id: _text(json['id']),
        name: _text(json['deduction_name']),
        amount: _count(json['amount']),
      );

  static PayslipOvertimeItem _overtimeItem(Map<String, dynamic> json) {
    return PayslipOvertimeItem(
      pieceId: _text(json['piece_id']),
      overtimeRequestId: _text(json['overtime_request_id']),
      workDate: _day(json['work_date']),
      startsAt: _instant(json['starts_at']),
      endsAt: _instant(json['ends_at']),
      payType: switch (json['pay_type']) {
        'percent' => PayslipOvertimePayType.percent,
        'fixed_per_hour' => PayslipOvertimePayType.fixedPerHour,
        _ => PayslipOvertimePayType.unknown,
      },
      payValue: _kip(json['pay_value']),
      paidMinutes: _wholeOrNull(json['paid_minutes']) ?? 0,
      baseSalary: _kip(json['base_salary']),
      daysPerMonth: _wholeOrNull(json['days_per_month']) ?? 0,
      amount: _kip(json['amount']),
    );
  }

  static PayslipRunStatus _runStatus(dynamic value) => switch (value) {
    'approved' => PayslipRunStatus.approved,
    'paid' => PayslipRunStatus.paid,
    _ => PayslipRunStatus.unknown,
  };

  static PayslipPaymentStatus _paymentStatus(dynamic value) => switch (value) {
    'pending' => PayslipPaymentStatus.pending,
    'processing' => PayslipPaymentStatus.processing,
    'paid' => PayslipPaymentStatus.paid,
    'failed' => PayslipPaymentStatus.failed,
    _ => PayslipPaymentStatus.unknown,
  };

  static String _text(dynamic value) => value is String ? value : '';

  static String? _textOrNull(dynamic value) =>
      value is String && value.isNotEmpty ? value : null;

  /// Whole kip. The server sends an integer; a JSON reader may still hand it
  /// over as `10000000.0`, which is the same number.
  static int _kip(dynamic value) => value is num ? value.toInt() : 0;

  /// A count that can have a fraction: days, hours, a decimal amount.
  static double _count(dynamic value) => value is num ? value.toDouble() : 0;

  static int? _wholeOrNull(dynamic value) => value is num ? value.toInt() : null;

  /// A month number, 1 to 12; anything else is not a month.
  static int? _month(dynamic value) {
    final month = _wholeOrNull(value);
    return month != null && month >= 1 && month <= 12 ? month : null;
  }

  /// An instant (RFC 3339, with its offset): read as that moment, shown in
  /// the phone's time.
  static DateTime? _instant(dynamic value) =>
      value is String ? DateTime.tryParse(value)?.toLocal() : null;

  /// A calendar day (`YYYY-MM-DD`): kept as that day, with no time-zone
  /// shift.
  static DateTime? _day(dynamic value) {
    final parsed = value is String ? DateTime.tryParse(value) : null;
    return parsed == null
        ? null
        : DateTime(parsed.year, parsed.month, parsed.day);
  }

  static Iterable<Map<String, dynamic>> _objects(dynamic value) =>
      value is List
      ? value.whereType<Map>().map(Map<String, dynamic>.from)
      : const [];
}
