import 'dart:async';
import 'dart:typed_data';

import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/salary_history/domain/entities/payslip.dart';
import 'package:next_on/features/salary_history/domain/entities/payslip_pdf.dart';
import 'package:next_on/features/salary_history/domain/entities/payslip_record.dart';
import 'package:next_on/features/salary_history/domain/repositories/salary_repository.dart';
import 'package:next_on/features/salary_history/presentation/services/payslip_pdf_saver.dart';

/// Programmable salary repository: each call returns the queued result and
/// records the argument it was given, so a widget test can assert which
/// year / payslip id the UI asked for.
class FakeSalaryRepository implements SalaryRepository {
  Result<Payslip>? detailResult;
  Result<PayslipPdf>? pdfResult;

  /// When set, `detail()` never completes — the detail page stays loading.
  bool hangDetail = false;

  final List<String> detailIds = [];
  final List<String> pdfIds = [];

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
    return myPayslipResult ??
        const Result.failure(
          Failure.network(message: 'not found', statusCode: 404),
        );
  }

  @override
  FutureResult<Payslip> detail(String id) {
    detailIds.add(id);
    if (hangDetail) return Completer<Result<Payslip>>().future;
    return Future.value(
      detailResult ??
          const Result.failure(Failure.network(message: 'not found', statusCode: 404)),
    );
  }

  @override
  FutureResult<PayslipPdf> pdf(String id) async {
    pdfIds.add(id);
    return pdfResult ??
        const Result.failure(Failure.network(message: 'not found', statusCode: 404));
  }
}

/// Records what the notifier asked to save and answers with [savedPath].
class FakePayslipPdfSaver implements PayslipPdfSaver {
  String? savedPath = '/tmp/payslip.pdf';
  final List<({Uint8List bytes, String fileName})> saves = [];

  @override
  Future<String?> save(PayslipPdf pdf, {required String fileName}) async {
    saves.add((bytes: pdf.bytes, fileName: fileName));
    return savedPath;
  }
}

/// A fully-populated payslip in the shape `PayslipModel` produces from the
/// confirmed backend contract — totals from the wire, sections itemised.
Payslip samplePayslip({
  String id = '2f2e2dfb-2a95-4ee5-ac4e-f97c21201820',
  required int year,
  int month = 8,
  PayslipStatus status = PayslipStatus.paid,
  bool withSections = true,
}) {
  return Payslip(
    id: id,
    year: year,
    month: month,
    status: status,
    payrollStatus: 'calculated',
    employeeName: 'Sandy Vang',
    employeeCode: 'EMP-002',
    position: 'IT Developer',
    department: 'IT Development',
    baseSalary: 12000000,
    grossSalary: 12800000,
    totalDeductions: 5373326,
    netSalary: 7426674,
    socialSecurity: 247500,
    employerSocialSecurity: 270000,
    incomeTax: 940249,
    workingDays: 22,
    overtimeHours: 0,
    unpaidLeaveDays: 0,
    earnings: withSections
        ? const [PayslipLine(code: 'BASIC', title: 'Base salary', amount: 12000000)]
        : const [],
    allowances: withSections
        ? const [PayslipLine(title: 'Position allowance', amount: 300000)]
        : const [],
    attendanceDeductions: withSections
        ? const [
            PayslipLine(
              code: 'LATE',
              title: 'Late arrival',
              quantity: 33,
              quantityUnit: 'minutes',
              amount: -31731,
              icon: PayslipLineIcon.lateArrival,
            ),
          ]
        : const [],
    statutoryDeductions: withSections
        ? const [
            PayslipLine(
              code: 'PIT',
              title: 'Income tax',
              amount: -940249,
              icon: PayslipLineIcon.incomeTax,
            ),
          ]
        : const [],
    taxableIncome: 12552500,
  );
}

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
  );
}
