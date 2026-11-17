import 'package:equatable/equatable.dart';

import '../../../../core/utils/ot_pay_type.dart';

/// Where HR's payroll run for this payslip stands (`status`). Staff only
/// ever see a payslip once its run is `approved` or `paid`.
enum PayslipRunStatus {
  approved,
  paid,

  /// A value the App does not know. Shown as it is, never guessed at.
  unknown,
}

/// Where the money itself stands (`payment_status`).
enum PayslipPaymentStatus {
  pending,
  processing,
  paid,
  failed,

  /// A value the App does not know.
  unknown,
}

/// Whether a payslip line adds to the pay or takes from it (`type`).
enum PayslipLineType { earning, deduction, unknown }

/// How an overtime piece is paid (`pay_type`). The type itself is core's
/// [OtPayType], shared with the overtime requests.
typedef PayslipOvertimePayType = OtPayType;

/// One payslip, exactly as the server sends it
/// (`GET /payroll/payslips/my` and `/my/:id`, `PayslipResponse`).
///
/// Every figure here is the server's. Nothing in this class adds money up:
/// the totals come from the server ([totalEarnings], [totalDeductions],
/// [netSalary]), and a sum worked out on the phone could disagree with the
/// payslip HR approved.
///
/// Money is whole kip (`int`). The three counts can be half a day or part of
/// an hour (`double`).
class PayslipRecord extends Equatable {
  final String id;
  final String payrollRunId;
  final String employeeId;
  final String employeeNumber;
  final String employeeName;
  final String? departmentName;
  final String? positionTitle;

  final int baseSalary;
  final int totalEarnings;
  final int totalDeductions;
  final int netSalary;
  final int employeeSs;
  final int employerSs;
  final int taxableIncome;
  final int incomeTax;

  final double workDays;
  final double overtimeHours;
  final double unpaidLeaveDays;

  final PayslipPaymentStatus paymentStatus;
  final PayslipRunStatus status;

  /// The pay period's year and month (1–12). Null when the server does not
  /// send them. Never worked out from [createdAt]: October's run is made on
  /// 1 November, and would read as November.
  final int? periodYear;
  final int? periodMonth;

  /// When the money was paid, local time. Null until it is, and while the
  /// server does not send it.
  final DateTime? paidAt;

  /// Earnings and deductions, in the server's order. Empty on a list row:
  /// only the single-payslip call carries them.
  final List<PayslipRecordLine> lines;
  final List<PayslipBenefit> benefits;
  final List<PayslipDeductionItem> deductionItems;
  final List<PayslipOvertimeItem> overtimeItems;

  /// When the payslip row was made and last changed, local time. Not the
  /// pay period.
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PayslipRecord({
    required this.id,
    this.payrollRunId = '',
    this.employeeId = '',
    this.employeeNumber = '',
    this.employeeName = '',
    this.departmentName,
    this.positionTitle,
    this.baseSalary = 0,
    this.totalEarnings = 0,
    this.totalDeductions = 0,
    this.netSalary = 0,
    this.employeeSs = 0,
    this.employerSs = 0,
    this.taxableIncome = 0,
    this.incomeTax = 0,
    this.workDays = 0,
    this.overtimeHours = 0,
    this.unpaidLeaveDays = 0,
    this.paymentStatus = PayslipPaymentStatus.unknown,
    this.status = PayslipRunStatus.unknown,
    this.periodYear,
    this.periodMonth,
    this.paidAt,
    this.lines = const [],
    this.benefits = const [],
    this.deductionItems = const [],
    this.overtimeItems = const [],
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    payrollRunId,
    employeeId,
    employeeNumber,
    employeeName,
    departmentName,
    positionTitle,
    baseSalary,
    totalEarnings,
    totalDeductions,
    netSalary,
    employeeSs,
    employerSs,
    taxableIncome,
    incomeTax,
    workDays,
    overtimeHours,
    unpaidLeaveDays,
    paymentStatus,
    status,
    periodYear,
    periodMonth,
    paidAt,
    lines,
    benefits,
    deductionItems,
    overtimeItems,
    createdAt,
    updatedAt,
  ];
}

/// One earning or deduction of a payslip (`lines[]`).
class PayslipRecordLine extends Equatable {
  final String id;
  final String componentCode;

  /// The component's name as HR's system holds it (English).
  final String componentName;
  final PayslipLineType type;
  final String category;

  /// Whole kip.
  final int amount;
  final bool isTaxable;
  final int sortOrder;

  /// How many of [quantityUnit] the line counts (86 minutes late, 1 time
  /// absent). Zero when the line has no count.
  final double quantity;
  final String? quantityUnit;

  /// The divisor and the amount the line's rate is worked from, as sent.
  final int ratePer;
  final int rateAmount;

  const PayslipRecordLine({
    required this.id,
    this.componentCode = '',
    this.componentName = '',
    this.type = PayslipLineType.unknown,
    this.category = '',
    this.amount = 0,
    this.isTaxable = false,
    this.sortOrder = 0,
    this.quantity = 0,
    this.quantityUnit,
    this.ratePer = 0,
    this.rateAmount = 0,
  });

  @override
  List<Object?> get props => [
    id,
    componentCode,
    componentName,
    type,
    category,
    amount,
    isTaxable,
    sortOrder,
    quantity,
    quantityUnit,
    ratePer,
    rateAmount,
  ];
}

/// One benefit paid with the payslip (`benefits[]`).
class PayslipBenefit extends Equatable {
  final String id;
  final String name;

  /// As sent, decimals and all; rounded only when shown.
  final double amount;

  const PayslipBenefit({required this.id, this.name = '', this.amount = 0});

  @override
  List<Object?> get props => [id, name, amount];
}

/// One named deduction taken from the payslip (`deduction_items[]`).
class PayslipDeductionItem extends Equatable {
  final String id;
  final String name;

  /// As sent, decimals and all; rounded only when shown.
  final double amount;

  const PayslipDeductionItem({
    required this.id,
    this.name = '',
    this.amount = 0,
  });

  @override
  List<Object?> get props => [id, name, amount];
}

/// One piece of overtime paid with the payslip (`overtime_items[]`).
class PayslipOvertimeItem extends Equatable {
  final String pieceId;
  final String overtimeRequestId;

  /// The day the overtime was worked (a calendar day, no time).
  final DateTime? workDate;

  /// When the piece started and ended, local time.
  final DateTime? startsAt;
  final DateTime? endsAt;
  final PayslipOvertimePayType payType;

  /// A percent of the hourly pay, or kip per hour, depending on [payType].
  final int payValue;
  final int paidMinutes;

  /// The base salary and days per month the piece was worked out from.
  final int baseSalary;
  final int daysPerMonth;

  /// Whole kip.
  final int amount;

  const PayslipOvertimeItem({
    required this.pieceId,
    this.overtimeRequestId = '',
    this.workDate,
    this.startsAt,
    this.endsAt,
    this.payType = PayslipOvertimePayType.unknown,
    this.payValue = 0,
    this.paidMinutes = 0,
    this.baseSalary = 0,
    this.daysPerMonth = 0,
    this.amount = 0,
  });

  @override
  List<Object?> get props => [
    pieceId,
    overtimeRequestId,
    workDate,
    startsAt,
    endsAt,
    payType,
    payValue,
    paidMinutes,
    baseSalary,
    daysPerMonth,
    amount,
  ];
}

/// The caller's newest payslip, as `GET /payroll/payslips/my/latest` sends
/// it: the newest of an approved or paid run by its pay month, whatever
/// year the salary list shows. Totals only; no status, name or lines.
class PayslipLatest extends Equatable {
  final String id;

  /// The pay month, 1 to 12, and its year.
  final int month;
  final int year;

  /// Whole kip.
  final int grossPay;
  final int totalDeductions;
  final int netPay;

  const PayslipLatest({
    required this.id,
    required this.month,
    required this.year,
    required this.grossPay,
    required this.totalDeductions,
    required this.netPay,
  });

  @override
  List<Object?> get props => [
    id,
    month,
    year,
    grossPay,
    totalDeductions,
    netPay,
  ];
}
