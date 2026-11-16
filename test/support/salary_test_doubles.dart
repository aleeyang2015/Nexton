import 'dart:async';
import 'dart:typed_data';

import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/salary_history/domain/entities/payslip.dart';
import 'package:next_on/features/salary_history/domain/entities/payslip_pdf.dart';
import 'package:next_on/features/salary_history/domain/repositories/salary_repository.dart';
import 'package:next_on/features/salary_history/presentation/services/payslip_pdf_saver.dart';

/// Programmable salary repository: each call returns the queued result and
/// records the argument it was given, so a widget test can assert which
/// year / payslip id the UI asked for.
class FakeSalaryRepository implements SalaryRepository {
  Result<List<Payslip>> historyResult = const Result.success([]);
  Result<Payslip>? detailResult;
  Result<PayslipPdf>? pdfResult;

  /// When set, `detail()` never completes — the detail page stays loading.
  bool hangDetail = false;

  final List<int> historyYears = [];
  final List<String> detailIds = [];
  final List<String> pdfIds = [];

  @override
  FutureResult<List<Payslip>> history(int year) async {
    historyYears.add(year);
    return historyResult.mapData(
      (all) => all.where((p) => p.year == year).toList(),
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
