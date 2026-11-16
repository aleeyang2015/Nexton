import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/network/api_client.dart';
import 'package:next_on/features/salary_history/data/datasources/salary_remote_data_source.dart';
import 'package:next_on/features/salary_history/data/repositories/salary_repository_impl.dart';

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
