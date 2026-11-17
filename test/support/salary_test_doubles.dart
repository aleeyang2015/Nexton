import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/salary_history/domain/entities/payslip_pdf.dart';
import 'package:next_on/features/salary_history/domain/entities/payslip_record.dart';
import 'package:next_on/features/salary_history/domain/repositories/salary_repository.dart';
import 'package:next_on/features/salary_history/presentation/services/payslip_pdf_files.dart';
import 'package:next_on/core/widgets/pdf_file_view.dart';

/// Programmable salary repository: each call returns the queued result and
/// records the argument it was given, so a widget test can assert which
/// year / payslip id the UI asked for.
class FakeSalaryRepository implements SalaryRepository {
  Result<PayslipPdf>? pdfResult;
  final List<String> pdfIds = [];

  /// When set, `pdf()` waits for it: the server still making the PDF.
  Completer<void>? holdPdf;

  /// The newest payslip; none by default (`"data": null`).
  Result<PayslipLatest?> latestResult = const Result.success(null);

  /// How many times the newest payslip was asked for.
  int latestCalls = 0;

  /// When set, `myLatestPayslip()` waits for it.
  Completer<void>? holdLatest;

  /// When set, `myPayslip()` never completes — the payslip page stays
  /// loading.
  bool hangMyPayslip = false;

  /// When set, `myPayslip()` answers after this long, as a real network
  /// does, so a frame is drawn while it loads.
  Duration myPayslipDelay = Duration.zero;

  /// The real payslips, as the server sends them; none by default.
  Result<List<PayslipRecord>> myPayslipsResult = const Result.success([]);
  Result<PayslipRecord>? myPayslipResult;
  final List<int> myPayslipsYears = [];
  final List<String> myPayslipIds = [];

  /// When set, `myPayslips()` waits for it: a year whose answer is slow.
  Completer<void>? holdMyPayslips;

  /// Answers by year when set; otherwise [myPayslipsResult] for any year.
  Result<List<PayslipRecord>> Function(int year)? myPayslipsByYear;

  @override
  FutureResult<List<PayslipRecord>> myPayslips(int year) async {
    myPayslipsYears.add(year);
    final byYear = myPayslipsByYear;
    final result = byYear != null ? byYear(year) : myPayslipsResult;
    await holdMyPayslips?.future;
    return result;
  }

  @override
  FutureResult<PayslipRecord> myPayslip(String id) async {
    myPayslipIds.add(id);
    if (hangMyPayslip) return Completer<Result<PayslipRecord>>().future;
    if (myPayslipDelay > Duration.zero) {
      await Future<void>.delayed(myPayslipDelay);
    }
    return myPayslipResult ??
        const Result.failure(
          Failure.network(message: 'not found', statusCode: 404),
        );
  }

  @override
  FutureResult<PayslipLatest?> myLatestPayslip() async {
    latestCalls++;
    final result = latestResult;
    await holdLatest?.future;
    return result;
  }

  @override
  FutureResult<PayslipPdf> pdf(String id) async {
    pdfIds.add(id);
    await holdPdf?.future;
    return pdfResult ??
        const Result.failure(Failure.network(message: 'not found', statusCode: 404));
  }
}

/// The temp files of opened PDFs, in memory: records what was written,
/// deleted and shared. A written file's path is
/// `/tmp/payslips/<n>/<name>`.
class FakePayslipPdfFiles extends PayslipPdfFiles {
  final List<PayslipPdf> writes = [];
  final List<String> deletes = [];
  final List<({String path, Rect? origin})> shares = [];

  /// When set, `share()` fails: the share sheet could not be opened.
  bool shareFails = false;

  /// When set, `share()` waits for it: the share sheet is still open.
  Completer<void>? holdShare;

  /// Paths written and not deleted since.
  final Set<String> live = {};

  @override
  Future<String> write(PayslipPdf pdf) async {
    writes.add(pdf);
    final path = '/tmp/payslips/${writes.length}/${pdf.fileName}';
    live.add(path);
    return path;
  }

  @override
  Future<void> delete(String path) async {
    deletes.add(path);
    live.remove(path);
  }

  @override
  Future<void> share(String path, {String? mimeType, Rect? origin}) async {
    if (shareFails) throw Exception('no share sheet');
    shares.add((path: path, origin: origin));
    await holdShare?.future;
  }
}

/// A sample PDF, as the server sends it for October's payslip.
final PayslipPdf samplePayslipPdf = PayslipPdf(
  bytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2d]),
  fileName: 'payslip-EMP-002-2026-10.pdf',
);

/// Puts a stand-in where the PDF viewer goes: the real one needs the phone's
/// PDF renderer. It shows "PDF " and the path.
Override fakePayslipPdfView() => pdfFileViewProvider.overrideWithValue(
  (path, _) => Text('PDF $path'),
);

/// A payslip as the server sends it in the year's list (totals only, no
/// lines): October 2026 by default, paid on 5 November. The figures match
/// [samplePayslip]'s, so a list row and its detail page agree.
PayslipRecord samplePayslipRecord({
  String id = '2f2e2dfb-2a95-4ee5-ac4e-f97c21201820',
  int? periodYear = 2026,
  int? periodMonth = 10,
  PayslipRunStatus status = PayslipRunStatus.paid,
  PayslipPaymentStatus paymentStatus = PayslipPaymentStatus.paid,
  DateTime? paidAt,
  bool paid = true,
  int netSalary = 7426674,
  double workDays = 22,
  double overtimeHours = 0,
  double unpaidLeaveDays = 0,
  String? positionTitle = 'IT Developer',
  DateTime? createdAt,
  List<PayslipRecordLine> lines = const [],
  List<PayslipBenefit> benefits = const [],
  List<PayslipDeductionItem> deductionItems = const [],
  List<PayslipOvertimeItem> overtimeItems = const [],
}) {
  return PayslipRecord(
    id: id,
    payrollRunId: 'run-1',
    employeeId: 'emp-1',
    employeeNumber: 'EMP-002',
    employeeName: 'Sandy Vang',
    departmentName: 'IT Development',
    positionTitle: positionTitle,
    baseSalary: 12000000,
    totalEarnings: 12800000,
    totalDeductions: 5373326,
    netSalary: netSalary,
    employeeSs: 247500,
    employerSs: 270000,
    taxableIncome: 12552500,
    incomeTax: 940249,
    workDays: workDays,
    overtimeHours: overtimeHours,
    unpaidLeaveDays: unpaidLeaveDays,
    paymentStatus: paymentStatus,
    status: status,
    periodYear: periodYear,
    periodMonth: periodMonth,
    paidAt: paidAt ?? (paid ? DateTime(2026, 11, 5, 10) : null),
    // Made on the 1st of the month after the one it pays.
    createdAt: createdAt ?? DateTime(2026, 11, 1, 9),
    lines: lines,
    benefits: benefits,
    deductionItems: deductionItems,
    overtimeItems: overtimeItems,
  );
}

/// The lines of a real payslip, as `GET /payroll/payslips/my/:id` sends
/// them: base pay, an OT line, the six attendance lines (most at zero),
/// social security, tax and a loan. With [samplePayslipBenefits] and
/// [samplePayslipDeductionItems] they are what the payslip page groups.
///
/// The amounts do not add up to [samplePayslipRecord]'s totals, on purpose:
/// a page that summed the lines would show figures no test expects.
const List<PayslipRecordLine> samplePayslipLines = [
  PayslipRecordLine(
    id: 'l-basic',
    componentCode: 'BASIC',
    componentName: 'Basic Salary',
    type: PayslipLineType.earning,
    category: 'fixed',
    amount: 12000000,
  ),
  PayslipRecordLine(
    id: 'l-ot',
    componentCode: 'OT',
    componentName: 'Overtime',
    type: PayslipLineType.earning,
    category: 'variable',
    amount: 162259,
    quantity: 2.25,
    quantityUnit: 'hours',
  ),
  PayslipRecordLine(
    id: 'l-late',
    componentCode: 'LATE',
    componentName: 'Late arrival penalty',
    type: PayslipLineType.deduction,
    category: 'penalty',
    amount: 68910,
    quantity: 95,
    quantityUnit: 'minutes',
    ratePer: 12480,
    rateAmount: 10000000,
  ),
  PayslipRecordLine(
    id: 'l-absent-late',
    componentCode: 'ABSENT-LATE',
    componentName: 'Absent-late penalty',
    type: PayslipLineType.deduction,
    category: 'penalty',
    quantityUnit: 'times',
  ),
  PayslipRecordLine(
    id: 'l-early',
    componentCode: 'EARLY-OUT',
    componentName: 'Early leave penalty',
    type: PayslipLineType.deduction,
    category: 'penalty',
    quantityUnit: 'minutes',
  ),
  PayslipRecordLine(
    id: 'l-missed',
    componentCode: 'MISSED-PART',
    componentName: 'Missed shift part',
    type: PayslipLineType.deduction,
    category: 'penalty',
    quantityUnit: 'minutes',
  ),
  PayslipRecordLine(
    id: 'l-absence',
    componentCode: 'ABSENCE',
    componentName: 'Absence penalty',
    type: PayslipLineType.deduction,
    category: 'penalty',
    quantityUnit: 'times',
  ),
  PayslipRecordLine(
    id: 'l-unpaid',
    componentCode: 'UNPAID-LEAVE',
    componentName: 'Unpaid leave',
    type: PayslipLineType.deduction,
    category: 'penalty',
    amount: 96154,
    quantity: 0.5,
    quantityUnit: 'days',
  ),
  PayslipRecordLine(
    id: 'l-ss',
    componentCode: 'EMP-SS',
    componentName: 'Employee Social Security',
    type: PayslipLineType.deduction,
    category: 'statutory',
    amount: 247500,
  ),
  PayslipRecordLine(
    id: 'l-pit',
    componentCode: 'PIT',
    componentName: 'Personal Income Tax',
    type: PayslipLineType.deduction,
    category: 'statutory',
    amount: 940249,
  ),
  PayslipRecordLine(
    id: 'l-loan',
    componentCode: 'LOAN',
    componentName: 'Loan: motorbike',
    type: PayslipLineType.deduction,
    category: 'fixed',
    amount: 500000,
  ),
];

const List<PayslipBenefit> samplePayslipBenefits = [
  PayslipBenefit(id: 'b-1', name: 'Position allowance', amount: 300000),
  PayslipBenefit(id: 'b-2', name: 'ຄ່າເດີນທາງ', amount: 25.5),
];

const List<PayslipDeductionItem> samplePayslipDeductionItems = [
  PayslipDeductionItem(id: 'd-1', name: 'ພັກວຽກ', amount: 100000),
];

/// The OT pieces behind [samplePayslipLines]' OT line (162,259), in the
/// server's order (by piece start):
///
/// * 28 September, the month before the payslip's October: 18:00–20:00 at
///   150%, 120 minutes paid, 43,269;
/// * 3 October, 17:00–18:30 at 20,000 kip per hour, 90 minutes, 30,000;
/// * 10 October, 07:00–08:00, inside the shift: 0 minutes, 0.
///
/// They add up to 73,269, not the line's 162,259, on purpose: a sheet that
/// summed the pieces would show a total no test expects.
final List<PayslipOvertimeItem> samplePayslipOvertimeItems = [
  PayslipOvertimeItem(
    pieceId: 'piece-1',
    overtimeRequestId: 'ot-1',
    workDate: DateTime(2026, 9, 28),
    startsAt: DateTime(2026, 9, 28, 18),
    endsAt: DateTime(2026, 9, 28, 20),
    payType: PayslipOvertimePayType.percent,
    payValue: 150,
    paidMinutes: 120,
    baseSalary: 12000000,
    daysPerMonth: 26,
    amount: 43269,
  ),
  PayslipOvertimeItem(
    pieceId: 'piece-2',
    overtimeRequestId: 'ot-2',
    workDate: DateTime(2026, 10, 3),
    startsAt: DateTime(2026, 10, 3, 17),
    endsAt: DateTime(2026, 10, 3, 18, 30),
    payType: PayslipOvertimePayType.fixedPerHour,
    payValue: 20000,
    paidMinutes: 90,
    amount: 30000,
  ),
  PayslipOvertimeItem(
    pieceId: 'piece-3',
    overtimeRequestId: 'ot-3',
    workDate: DateTime(2026, 10, 10),
    startsAt: DateTime(2026, 10, 10, 7),
    endsAt: DateTime(2026, 10, 10, 8),
    payType: PayslipOvertimePayType.percent,
    payValue: 200,
    paidMinutes: 0,
    amount: 0,
  ),
];

/// December 2026's payslip as `/my/latest` sends it: the newest one, in a
/// later year than the list may be showing.
const PayslipLatest sampleLatestPayslip = PayslipLatest(
  id: 'p-dec',
  month: 12,
  year: 2026,
  grossPay: 12800000,
  totalDeductions: 5373326,
  netPay: 7426674,
);
