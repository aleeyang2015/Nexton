import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/network/api_client.dart';
import 'package:next_on/core/network/api_error_mapper.dart';
import 'package:next_on/core/network/network_info.dart';
import 'package:next_on/features/salary_history/data/datasources/salary_remote_data_source.dart';
import 'package:next_on/features/salary_history/data/repositories/salary_repository_impl.dart';

/// Serves one canned answer of raw bytes, with its headers, and records the
/// request.
class _BytesAdapter implements HttpClientAdapter {
  int status = 200;
  List<int> body = const [];
  Map<String, List<String>> headers = const {};
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromBytes(body, status, headers: headers);
  }

  @override
  void close({bool force = false}) {}
}

/// `GET /payroll/payslips/my/:id/pdf`: the PDF's bytes and its name, or the
/// server's JSON refusal read to its code.
void main() {
  late _BytesAdapter adapter;
  late SalaryRepositoryImpl repository;

  final pdfBytes = utf8.encode('%PDF-1.7\n...payslip...');

  setUp(() {
    adapter = _BytesAdapter();
    final dio = Dio()
      ..httpClientAdapter = adapter
      ..interceptors.add(NetworkInterceptor());
    repository = SalaryRepositoryImpl(
      remote: SalaryRemoteDataSourceImpl(ApiClient(dio: dio)),
    );
  });

  void servePdf({String? disposition}) => adapter
    ..status = 200
    ..body = pdfBytes
    ..headers = {
      Headers.contentTypeHeader: ['application/pdf'],
      if (disposition != null) 'content-disposition': [disposition],
    };

  void refuse(int status, String code, String message) => adapter
    ..status = status
    ..body = utf8.encode(
      jsonEncode({
        'success': false,
        'error': {'code': code, 'message': message},
      }),
    )
    ..headers = {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    };

  Future<Failure> failureOf(String id) async {
    final result = await repository.pdf(id);
    return result.failureOrNull!;
  }

  test('asks for the payslip\'s PDF, as bytes', () async {
    servePdf(disposition: 'inline; filename="payslip-EMP-002-2026-09.pdf"');

    await repository.pdf('p-sep');

    expect(adapter.lastRequest?.path, endsWith('/payroll/payslips/my/p-sep/pdf'));
    expect(adapter.lastRequest?.responseType, ResponseType.bytes);
  });

  test('the bytes and the file name from Content-Disposition', () async {
    servePdf(disposition: 'inline; filename="payslip-EMP-002-2026-09.pdf"');

    final pdf = (await repository.pdf('p-sep')).dataOrNull!;

    expect(pdf.bytes, pdfBytes);
    expect(pdf.fileName, 'payslip-EMP-002-2026-09.pdf');
  });

  test('with no name from the server the file is payslip-<id>.pdf', () async {
    servePdf();

    final pdf = (await repository.pdf('p-sep')).dataOrNull!;

    expect(pdf.fileName, 'payslip-p-sep.pdf');
  });

  test('a header with no file name in it gives the same fallback', () async {
    servePdf(disposition: 'inline');

    final pdf = (await repository.pdf('p-sep')).dataOrNull!;

    expect(pdf.fileName, 'payslip-p-sep.pdf');
  });

  test('404 NOT_FOUND: the JSON body is read, the status and code kept', () async {
    refuse(404, 'NOT_FOUND', 'Payslip not found');

    final failure = await failureOf('p-x');

    expect(failure, isA<NetworkFailure>());
    expect((failure as NetworkFailure).statusCode, 404);
    expect(failure.errorCode, 'NOT_FOUND');
  });

  test('500 INTERNAL_ERROR: a server failure with its code', () async {
    refuse(500, 'INTERNAL_ERROR', 'could not render');

    final failure = await failureOf('p-sep');

    expect(failure, isA<ServerFailure>());
    expect((failure as ServerFailure).errorCode, 'INTERNAL_ERROR');
  });

  test('403 MODULE_NOT_ACTIVE: a refusal with its code', () async {
    refuse(403, ApiErrorCodes.moduleNotActive, 'Payroll is not active');

    final failure = await failureOf('p-sep');

    expect(failure, isA<ValidationFailure>());
    expect((failure as ValidationFailure).code, ApiErrorCodes.moduleNotActive);
  });

  test('a 200 that is not a PDF (JSON) is an error, never a file', () async {
    adapter
      ..status = 200
      ..body = utf8.encode(jsonEncode({'success': true, 'data': {}}))
      ..headers = {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      };

    final failure = await failureOf('p-sep');

    expect(failure, isA<ValidationFailure>());
    expect(failure.message, SalaryRemoteDataSourceImpl.pdfInvalidToken);
  });

  test('an empty 200 is an error too', () async {
    adapter
      ..status = 200
      ..body = const []
      ..headers = {
        Headers.contentTypeHeader: ['application/pdf'],
      };

    expect(await failureOf('p-sep'), isA<ValidationFailure>());
  });
}
