import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/network/api_client.dart';
import 'package:next_on/features/salary_history/data/datasources/salary_remote_data_source.dart';
import 'package:next_on/features/salary_history/data/models/payslip_model.dart';
import 'package:next_on/features/salary_history/data/repositories/salary_repository_impl.dart';
import 'package:next_on/features/salary_history/domain/entities/payslip.dart';

/// Serves one canned response — JSON or raw bytes — and records the request
/// that asked for it.
class _StubAdapter implements HttpClientAdapter {
  int status = 200;
  Object body = const <String, dynamic>{};
  Map<String, List<String>> headers = const {};

  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;

    final raw = body;
    if (raw is List<int>) {
      return ResponseBody.fromBytes(
        Uint8List.fromList(raw),
        status,
        headers: {
          Headers.contentTypeHeader: ['application/pdf'],
          ...headers,
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode(raw),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        ...headers,
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// The confirmed `GET /payroll/payslips/my` row (list shape — no lines).
const _listRow = <String, dynamic>{
  'id': '2f2e2dfb-2a95-4ee5-ac4e-f97c21201820',
  'payroll_run_id': '60e08b66-2542-42e9-844c-c91626fce33d',
  'employee_id': '729781ee-ab70-40ed-8b6f-eacdfd5dfde6',
  'employee_number': 'EMP-007',
  'employee_name': 'alexsander vang',
  'department_name': 'haltech',
  'position_title': 'support ',
  'base_salary': 10000000,
  'total_earnings': 11800000,
  'total_deductions': 1777492,
  'net_salary': 10022508,
  'employee_ss': 247500,
  'employer_ss': 270000,
  'taxable_income': 11552500,
  'income_tax': 840249,
  'work_days': 0.82,
  'overtime_hours': 0,
  'unpaid_leave_days': 0,
  'payment_status': 'pending',
  'status': 'calculated',
  'created_at': '2026-08-11T15:30:13.194803+07:00',
  'updated_at': '2026-09-14T21:03:56.040049+07:00',
};

Map<String, dynamic> _line({
  required String code,
  required String name,
  required String type,
  required String category,
  required num amount,
  required int sortOrder,
  num quantity = 0,
  String? unit,
  num ratePer = 0,
  num rateAmount = 0,
}) => {
  'id': 'line-$code',
  'component_code': code,
  'component_name': name,
  'type': type,
  'category': category,
  'amount': amount,
  'is_taxable': type == 'earning',
  'sort_order': sortOrder,
  'quantity': quantity,
  'quantity_unit': unit,
  'rate_per': ratePer,
  'rate_amount': rateAmount,
};

/// The confirmed `GET /payroll/payslips/my/{id}` body. Lines are listed out
/// of `sort_order` on purpose, to prove the mapper sorts them.
final _detailRow = <String, dynamic>{
  ..._listRow,
  'lines': [
    _line(code: 'PIT', name: 'Personal Income Tax', type: 'deduction', category: 'statutory', amount: 840249, sortOrder: 990),
    _line(code: 'BASIC', name: 'Basic Salary', type: 'earning', category: 'fixed', amount: 10000000, sortOrder: 0),
    _line(code: 'LATE', name: 'Late arrival penalty', type: 'deduction', category: 'penalty', amount: 68910, sortOrder: 960, quantity: 86, unit: 'minutes', ratePer: 12480, rateAmount: 10000000),
    _line(code: 'ABSENT-LATE', name: 'Absent-late penalty', type: 'deduction', category: 'penalty', amount: 384615, sortOrder: 962, quantity: 1, unit: 'times', ratePer: 26, rateAmount: 10000000),
    _line(code: 'EARLY-OUT', name: 'Early leave penalty', type: 'deduction', category: 'penalty', amount: 136218, sortOrder: 965, quantity: 170, unit: 'minutes', ratePer: 12480, rateAmount: 10000000),
    _line(code: 'ABSENCE', name: 'Absence penalty', type: 'deduction', category: 'penalty', amount: 0, sortOrder: 970, quantity: 0, unit: 'times', ratePer: 26, rateAmount: 10000000),
    _line(code: 'EMP-SS', name: 'Employee Social Security', type: 'deduction', category: 'statutory', amount: 247500, sortOrder: 980),
  ],
  'benefits': [
    {'id': 'b1', 'payslip_id': _listRow['id'], 'source_type': 'employee_benefits', 'source_id': 's1', 'name': 'ປະກັນສຸຂະພາບ', 'amount': 1000000},
    {'id': 'b2', 'payslip_id': _listRow['id'], 'source_type': 'employee_education_levels', 'source_id': 's2', 'name': 'ປະລິນຍາຕີ', 'amount': 500000},
    {'id': 'b3', 'source_type': 'employee_job_titles', 'source_id': 's3', 'name': 'ວິສະວະກອນຊອບແວ', 'amount': 300000},
  ],
  'deduction_items': [
    {'id': 'd1', 'payslip_id': _listRow['id'], 'deduction_id': 'dd1', 'deduction_name': 'ພັກວຽກ', 'amount': 100000},
  ],
};

final _pdfBytes = Uint8List.fromList([...utf8.encode('%PDF-1.7\n'), 0, 1, 2, 3]);

void main() {
  late _StubAdapter adapter;
  late SalaryRemoteDataSourceImpl source;
  late SalaryRepositoryImpl repository;

  setUp(() {
    adapter = _StubAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    source = SalaryRemoteDataSourceImpl(ApiClient(dio: dio));
    repository = SalaryRepositoryImpl(remote: source);
  });

  group('history', () {
    test('asks for the selected year with status=all and limit=10', () async {
      adapter.body = {'success': true, 'data': [], 'meta': {'per_page': 10, 'has_more': false}};

      await source.history(2025);

      final request = adapter.lastRequest!;
      expect(request.method, 'GET');
      expect(request.path, '/payroll/payslips/my');
      expect(request.queryParameters, {'year': 2025, 'status': 'all', 'limit': 10});
    });

    test('maps the confirmed list row onto the payslip entity', () async {
      adapter.body = {'success': true, 'data': [_listRow], 'meta': {'per_page': 10, 'has_more': false}};

      final payslips = await source.history(2026);

      expect(payslips, hasLength(1));
      final p = payslips.single;
      expect(p.id, '2f2e2dfb-2a95-4ee5-ac4e-f97c21201820');
      // Period comes from created_at — the only date the row carries.
      expect(p.year, 2026);
      expect(p.month, 8);
      expect(p.paidDate, isNull);
      // Identity.
      expect(p.employeeCode, 'EMP-007');
      expect(p.employeeName, 'alexsander vang');
      expect(p.department, 'haltech');
      expect(p.position, 'support'); // trailing space trimmed
      // Totals are the backend's, not recomputed.
      expect(p.baseSalary, 10000000);
      expect(p.grossSalary, 11800000);
      expect(p.totalDeductions, 1777492);
      expect(p.netSalary, 10022508);
      expect(p.allowance, 1800000);
      expect(p.otherDeductions, 1777492 - 247500 - 840249);
      // Employee vs employer social security stay apart.
      expect(p.socialSecurity, 247500);
      expect(p.employerSocialSecurity, 270000);
      expect(p.incomeTax, 840249);
      expect(p.taxableIncome, 11552500);
      expect(p.socialSecurityRate, 0);
      expect(p.socialSecurityBase, 0);
      // Statistics.
      expect(p.workingDays, 0.82);
      expect(p.overtimeHours, 0);
      expect(p.unpaidLeaveDays, 0);
      // payment_status drives the Paid/Pending chip; status is kept apart.
      expect(p.status, PayslipStatus.pending);
      expect(p.payrollStatus, 'calculated');
      // The list shape has no line items.
      expect(p.earnings, isEmpty);
      expect(p.allowances, isEmpty);
      expect(p.attendanceDeductions, isEmpty);
      expect(p.statutoryDeductions, isEmpty);
    });

    test('payment_status paid → paid; anything else → pending', () {
      expect(PayslipModel.fromJson({..._listRow, 'payment_status': 'paid'}).status, PayslipStatus.paid);
      expect(PayslipModel.fromJson({..._listRow, 'payment_status': 'pending'}).status, PayslipStatus.pending);
      expect(PayslipModel.fromJson({..._listRow, 'payment_status': null}).status, PayslipStatus.pending);
    });

    test('orders payslips newest period first', () async {
      adapter.body = {
        'success': true,
        'data': [
          {..._listRow, 'id': 'jun', 'created_at': '2026-06-10T09:00:00+07:00'},
          {..._listRow, 'id': 'aug', 'created_at': '2026-08-11T15:30:13+07:00'},
          {..._listRow, 'id': 'jul', 'created_at': '2026-07-12T09:00:00+07:00'},
        ],
      };

      final payslips = await source.history(2026);

      expect(payslips.map((p) => p.id), ['aug', 'jul', 'jun']);
    });

    test('an empty year is an empty list, not an error', () async {
      adapter.body = {'success': true, 'data': [], 'meta': {'per_page': 10, 'has_more': false}};

      final result = await repository.history(2019);

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, isEmpty);
    });

    test('a 401 surfaces as an auth failure through the repository', () async {
      adapter
        ..status = 401
        ..body = {'success': false, 'error': {'code': 'MISSING_TOKEN', 'message': 'Authorization header is required'}};

      final result = await repository.history(2026);

      expect(result.failureOrNull, isA<AuthFailure>());
      expect(result.failureOrNull!.message, 'Authorization header is required');
    });

    test('a 500 surfaces as a server failure', () async {
      adapter
        ..status = 500
        ..body = {'success': false, 'error': {'code': 'INTERNAL_ERROR', 'message': 'boom'}};

      final result = await repository.history(2026);

      expect(result.failureOrNull, isA<ServerFailure>());
    });

    test('a body that is not the list envelope is a validation failure', () async {
      adapter.body = {'success': true, 'data': 'nope'};

      final result = await repository.history(2026);

      expect(result.failureOrNull, isA<ValidationFailure>());
    });
  });

  group('detail', () {
    test('asks for the given payslip id', () async {
      adapter.body = {'success': true, 'data': _detailRow};

      await source.detail('abc-123');

      expect(adapter.lastRequest!.method, 'GET');
      expect(adapter.lastRequest!.path, '/payroll/payslips/my/abc-123');
    });

    test('keeps the backend totals on the detail entity', () async {
      adapter.body = {'success': true, 'data': _detailRow};

      final p = await source.detail(_listRow['id'] as String);

      expect(p.grossSalary, 11800000);
      expect(p.totalDeductions, 1777492);
      expect(p.netSalary, 10022508);
      expect(p.socialSecurity, 247500);
      expect(p.employerSocialSecurity, 270000);
      expect(p.incomeTax, 840249);
      expect(p.workingDays, 0.82);
      expect(p.overtimeHours, 0);
      expect(p.unpaidLeaveDays, 0);
      expect(p.status, PayslipStatus.pending);
      expect(p.payrollStatus, 'calculated');
    });

    test('splits lines by type/category and sorts them by sort_order', () async {
      adapter.body = {'success': true, 'data': _detailRow};

      final p = await source.detail(_listRow['id'] as String);

      expect(p.earnings, const [
        PayslipLine(code: 'BASIC', title: 'Basic Salary', amount: 10000000),
      ]);

      expect(p.attendanceDeductions.map((l) => l.title), [
        'Late arrival penalty',
        'Absent-late penalty',
        'Early leave penalty',
        'Absence penalty',
      ]);
      expect(p.attendanceDeductions.map((l) => l.amount), [-68910, -384615, -136218, 0]);
      expect(p.attendanceDeductions.map((l) => l.icon), [
        PayslipLineIcon.lateArrival,
        PayslipLineIcon.absentLate,
        PayslipLineIcon.earlyOut,
        PayslipLineIcon.absence,
      ]);
      // The wire's own code/quantity/unit, kept raw — the caption text is
      // built per-locale by SalaryHistoryCopy.lineCaption.
      expect(p.attendanceDeductions.map((l) => l.code), [
        'LATE',
        'ABSENT-LATE',
        'EARLY-OUT',
        'ABSENCE',
      ]);
      expect(p.attendanceDeductions.map((l) => l.quantity), [86, 1, 170, 0]);
      expect(p.attendanceDeductions.map((l) => l.quantityUnit), [
        'minutes',
        'times',
        'minutes',
        'times',
      ]);

      // Statutory lines in sort order, then the ad-hoc deduction items.
      expect(p.statutoryDeductions.map((l) => l.title), [
        'Employee Social Security',
        'Personal Income Tax',
        'ພັກວຽກ',
      ]);
      expect(p.statutoryDeductions.map((l) => l.amount), [-247500, -840249, -100000]);
      expect(p.statutoryDeductions.map((l) => l.icon), [
        PayslipLineIcon.socialSecurity,
        PayslipLineIcon.incomeTax,
        PayslipLineIcon.otherDeduction,
      ]);
      expect(p.statutoryDeductions.map((l) => l.code), ['EMP-SS', 'PIT', '']);

      // The section totals foot to the wire totals.
      final earned = [...p.earnings, ...p.allowances].fold<double>(0, (s, l) => s + l.amount);
      final deducted = [...p.attendanceDeductions, ...p.statutoryDeductions].fold<double>(0, (s, l) => s + l.amount);
      expect(earned, p.grossSalary);
      expect(-deducted, p.totalDeductions);
    });

    test('benefits become the welfare/allowances section', () async {
      adapter.body = {'success': true, 'data': _detailRow};

      final p = await source.detail(_listRow['id'] as String);

      // Free text a tenant typed in: no component code to translate on, so
      // the backend's own wording is all there is.
      expect(p.allowances, const [
        PayslipLine(title: 'ປະກັນສຸຂະພາບ', amount: 1000000),
        PayslipLine(title: 'ປະລິນຍາຕີ', amount: 500000),
        PayslipLine(title: 'ວິສະວະກອນຊອບແວ', amount: 300000),
      ]);
    });

    test('a deduction is placed by its type, not its component code', () {
      final p = PayslipModel.fromJson({
        ..._listRow,
        'lines': [
          // An unknown penalty code still lands under attendance …
          _line(code: 'NEW-PENALTY', name: 'New penalty', type: 'deduction', category: 'penalty', amount: 10, sortOrder: 1),
          // … an unknown statutory code under statutory/other …
          _line(code: 'NEW-STAT', name: 'New statutory', type: 'deduction', category: 'statutory', amount: 20, sortOrder: 2),
          // … and an unknown type is not printed at all.
          _line(code: 'ER-SS', name: 'Employer SS', type: 'employer_contribution', category: 'statutory', amount: 270000, sortOrder: 3),
        ],
      });

      expect(p.attendanceDeductions.single.title, 'New penalty');
      expect(p.attendanceDeductions.single.icon, PayslipLineIcon.otherDeduction);
      expect(p.statutoryDeductions.single.title, 'New statutory');
      expect(p.statutoryDeductions.single.icon, PayslipLineIcon.otherDeduction);
      expect(p.earnings, isEmpty);
    });

    test('tolerates null and missing fields', () {
      final p = PayslipModel.fromJson({
        'id': 'x',
        'employee_name': null,
        'base_salary': null,
        'lines': null,
        'benefits': null,
        'deduction_items': null,
        'created_at': null,
      });

      expect(p.id, 'x');
      expect(p.employeeName, '');
      expect(p.baseSalary, 0);
      expect(p.grossSalary, 0);
      expect(p.netSalary, 0);
      expect(p.status, PayslipStatus.pending);
      expect(p.earnings, isEmpty);
      expect(p.allowances, isEmpty);
      expect(p.statutoryDeductions, isEmpty);
      expect(p.month, inInclusiveRange(1, 12));
    });

    test('an unknown id is a 404 network failure', () async {
      adapter
        ..status = 404
        ..body = {'success': false, 'error': {'code': 'NOT_FOUND', 'message': 'Payslip not found'}};

      final result = await repository.detail('missing');

      final failure = result.failureOrNull;
      expect(failure, isA<NetworkFailure>());
      expect((failure as NetworkFailure).statusCode, 404);
      expect(failure.errorCode, 'NOT_FOUND');
    });
  });

  group('pdf', () {
    test('asks for the payslip PDF as raw bytes', () async {
      adapter.body = _pdfBytes;

      await source.pdf('abc-123');

      expect(adapter.lastRequest!.method, 'GET');
      expect(adapter.lastRequest!.path, '/payroll/payslips/my/abc-123/pdf');
      expect(adapter.lastRequest!.responseType, ResponseType.bytes);
    });

    test('returns the bytes and the server-suggested file name', () async {
      adapter
        ..body = _pdfBytes
        ..headers = {
          'content-disposition': ['attachment; filename="payslip-2026-08.pdf"'],
        };

      final pdf = await source.pdf('abc-123');

      expect(pdf.bytes, _pdfBytes);
      expect(pdf.fileName, 'payslip-2026-08.pdf');
    });

    test('no Content-Disposition → no file name', () async {
      adapter.body = _pdfBytes;

      final pdf = await source.pdf('abc-123');

      expect(pdf.fileName, isNull);
    });

    test('an empty body is rejected as an invalid PDF', () async {
      adapter.body = <int>[];

      final result = await repository.pdf('abc-123');

      final failure = result.failureOrNull;
      expect(failure, isA<ValidationFailure>());
      expect(failure!.message, SalaryRemoteDataSourceImpl.pdfInvalidToken);
    });

    test('a body that is not a PDF is rejected', () async {
      adapter.body = utf8.encode('<html>login</html>');

      final result = await repository.pdf('abc-123');

      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('an error status surfaces as a failure, not bytes', () async {
      adapter
        ..status = 404
        ..body = {'success': false, 'error': {'code': 'NOT_FOUND', 'message': 'Payslip not found'}};

      final result = await repository.pdf('missing');

      expect(result.failureOrNull, isA<NetworkFailure>());
      expect((result.failureOrNull as NetworkFailure).statusCode, 404);
    });
  });
}
