import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/network/api_client.dart';
import 'package:next_on/core/network/network_info.dart';
import 'package:next_on/features/salary_history/data/datasources/salary_remote_data_source.dart';
import 'package:next_on/features/salary_history/data/repositories/salary_repository_impl.dart';
import 'package:next_on/features/salary_history/domain/entities/payslip_record.dart';

import 'payslip_record_model_test.dart' show detailRow, listRow;

/// Serves one canned response and records the request that asked for it.
class _StubAdapter implements HttpClientAdapter {
  int status = 200;
  Object body = const <String, dynamic>{};
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _StubAdapter adapter;
  late SalaryRemoteDataSourceImpl source;
  late SalaryRepositoryImpl repository;

  setUp(() {
    adapter = _StubAdapter();
    // The App's own error interceptor, so a refusal reaches the repository
    // the way it does in the App.
    final dio = Dio()
      ..httpClientAdapter = adapter
      ..interceptors.add(NetworkInterceptor());
    source = SalaryRemoteDataSourceImpl(ApiClient(dio: dio));
    repository = SalaryRepositoryImpl(remote: source);
  });

  void refuse(int status, String code, [String message = 'refused']) => adapter
    ..status = status
    ..body = {
      'success': false,
      'error': {'code': code, 'message': message},
    };

  group('myPayslips', () {
    test('GET /payroll/payslips/my with the year, page 1 and 100 a page, and '
        'no status', () async {
      adapter.body = {'success': true, 'data': <Object>[]};

      await source.myPayslips(2026);

      final request = adapter.lastRequest!;
      expect(request.method, 'GET');
      expect(request.path, '/payroll/payslips/my');
      expect(request.queryParameters, {
        'year': 2026,
        'page': 1,
        'per_page': 100,
      });
    });

    test('reads the rows in the order the server sent them', () async {
      adapter.body = {
        'success': true,
        'data': [
          {...listRow(), 'id': 'p-nov', 'period_year': 2026, 'period_month': 11},
          {...listRow(), 'id': 'p-oct', 'period_year': 2026, 'period_month': 10},
          {...listRow(), 'id': 'p-dec', 'period_year': 2026, 'period_month': 12},
        ],
        'meta': {'page': 1, 'per_page': 100, 'total': 3, 'total_pages': 1},
      };

      final payslips = await source.myPayslips(2026);

      expect(payslips.map((p) => p.id), ['p-nov', 'p-oct', 'p-dec']);
      expect(payslips.first.netSalary, 10022508);
      expect(payslips.first.lines, isEmpty);
    });

    test('200 with an empty list (no employee linked) is an empty list, not '
        'an error', () async {
      adapter.body = {'success': true, 'data': <Object>[]};

      final result = await repository.myPayslips(2026);

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, isEmpty);
    });

    test('403 MODULE_NOT_ACTIVE keeps its code, and is not a sign-in '
        'failure', () async {
      refuse(403, 'MODULE_NOT_ACTIVE', 'payroll is not active');

      final failure = (await repository.myPayslips(2026)).failureOrNull!;

      expect(failure, isA<ValidationFailure>());
      expect((failure as ValidationFailure).code, 'MODULE_NOT_ACTIVE');
    });

    test('400 VALIDATION_ERROR (a bad year) keeps its code', () async {
      refuse(400, 'VALIDATION_ERROR', 'year must be a number');

      final failure = (await repository.myPayslips(0)).failureOrNull!;

      expect((failure as ValidationFailure).code, 'VALIDATION_ERROR');
    });

    test('a 500 is a server failure, with its status', () async {
      refuse(500, 'INTERNAL_ERROR');

      final failure = (await repository.myPayslips(2026)).failureOrNull!;

      expect(failure, isA<ServerFailure>());
      expect((failure as ServerFailure).statusCode, 500);
    });
  });

  group('myPayslip', () {
    test('GET /payroll/payslips/my/:id, and reads the whole payslip', () async {
      adapter.body = {'success': true, 'data': detailRow()};

      final payslip = await source.myPayslip(
        '2f2e2dfb-2a95-4ee5-ac4e-f97c21201820',
      );

      final request = adapter.lastRequest!;
      expect(request.method, 'GET');
      expect(
        request.path,
        '/payroll/payslips/my/2f2e2dfb-2a95-4ee5-ac4e-f97c21201820',
      );
      expect(request.queryParameters, isEmpty);
      expect(payslip.lines, hasLength(2));
      expect(payslip.benefits, hasLength(2));
      expect(payslip.deductionItems, hasLength(1));
      expect(payslip.overtimeItems, hasLength(1));
      expect(payslip.status, PayslipRunStatus.paid);
    });

    test('404 NOT_FOUND keeps statusCode 404, for the page to say so',
        () async {
      refuse(404, 'NOT_FOUND', 'payslip not found');

      final failure = (await repository.myPayslip('p-gone')).failureOrNull!;

      expect(failure, isA<NetworkFailure>());
      expect((failure as NetworkFailure).statusCode, 404);
      expect(failure.errorCode, 'NOT_FOUND');
    });

    test('403 MODULE_NOT_ACTIVE keeps its code', () async {
      refuse(403, 'MODULE_NOT_ACTIVE');

      final failure = (await repository.myPayslip('p-1')).failureOrNull!;

      expect((failure as ValidationFailure).code, 'MODULE_NOT_ACTIVE');
    });

    test('a 500 (an id that is not a UUID) is a server failure', () async {
      refuse(500, 'INTERNAL_ERROR');

      final failure = (await repository.myPayslip('not-a-uuid')).failureOrNull!;

      expect(failure, isA<ServerFailure>());
    });

    test('a body that is not a payslip is a failure, not a crash', () async {
      adapter.body = {'success': true, 'data': 'nope'};

      final result = await repository.myPayslip('p-1');

      expect(result.isFailure, isTrue);
    });
  });

  group('myLatestPayslip', () {
    /// `GET /payroll/payslips/my/latest`, as the server fills it
    /// (`mobile.go:205-215`).
    Map<String, dynamic> latest() => {
      'id': 'p-dec',
      'period': '2026-12',
      'period_label': 'December 2026',
      'month': 12,
      'year': 2026,
      'earnings': [
        {'label': 'Basic Salary', 'amount': 12000000},
      ],
      'deductions': [
        {'label': 'Income Tax', 'amount': 940249},
      ],
      'gross_pay': 12800000,
      'total_deductions': 5373326,
      'net_pay': 7426674,
    };

    test('GET /payroll/payslips/my/latest, with no query', () async {
      adapter.body = {'success': true, 'data': latest()};

      await source.myLatestPayslip();

      final request = adapter.lastRequest!;
      expect(request.method, 'GET');
      expect(request.path, '/payroll/payslips/my/latest');
      expect(request.queryParameters, isEmpty);
    });

    test('reads the id, the month and year, and the three totals', () async {
      adapter.body = {'success': true, 'data': latest()};

      final payslip = (await source.myLatestPayslip())!;

      expect(payslip.id, 'p-dec');
      expect(payslip.month, 12);
      expect(payslip.year, 2026);
      expect(payslip.grossPay, 12800000);
      expect(payslip.totalDeductions, 5373326);
      expect(payslip.netPay, 7426674);
    });

    test('a whole number sent as 7426674.0 is read as 7426674', () async {
      adapter.body = {
        'success': true,
        'data': {...latest(), 'net_pay': 7426674.0, 'month': 12.0},
      };

      final payslip = (await source.myLatestPayslip())!;

      expect(payslip.netPay, 7426674);
      expect(payslip.month, 12);
    });

    test('"data": null (nothing yet, or no employee linked) is null, not '
        'the envelope', () async {
      adapter.body = {'success': true, 'data': null};

      final result = await repository.myLatestPayslip();

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, isNull);
    });

    test('an answer with no data at all is null too', () async {
      adapter.body = {'success': true};

      expect((await repository.myLatestPayslip()).dataOrNull, isNull);
    });

    test('a fraction of a kip is refused, never shown rounded', () async {
      adapter.body = {
        'success': true,
        'data': {...latest(), 'net_pay': 7426674.5},
      };

      expect((await repository.myLatestPayslip()).isFailure, isTrue);
    });

    test('a month that is not 1 to 12, or no year, is refused', () async {
      adapter.body = {
        'success': true,
        'data': {...latest(), 'month': 13},
      };
      expect((await repository.myLatestPayslip()).isFailure, isTrue);

      adapter.body = {
        'success': true,
        'data': {...latest()}..remove('year'),
      };
      expect((await repository.myLatestPayslip()).isFailure, isTrue);
    });

    test('no id is refused: the card could not open the payslip', () async {
      adapter.body = {
        'success': true,
        'data': {...latest(), 'id': ''},
      };

      expect((await repository.myLatestPayslip()).isFailure, isTrue);
    });

    test('a missing total is refused, never shown as 0', () async {
      adapter.body = {
        'success': true,
        'data': {...latest()}..remove('net_pay'),
      };

      expect((await repository.myLatestPayslip()).isFailure, isTrue);
    });

    test('403 MODULE_NOT_ACTIVE keeps its code', () async {
      refuse(403, 'MODULE_NOT_ACTIVE', 'payroll is not active');

      final failure = (await repository.myLatestPayslip()).failureOrNull!;

      expect((failure as ValidationFailure).code, 'MODULE_NOT_ACTIVE');
    });

    test('a body that is not a payslip is a failure, not a crash', () async {
      adapter.body = {'success': true, 'data': 'nope'};

      expect((await repository.myLatestPayslip()).isFailure, isTrue);
    });
  });
}
