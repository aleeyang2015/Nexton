import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/network/api_error_mapper.dart';
import 'package:next_on/core/network/api_response.dart';

/// A call that asks for bytes (the payslip PDF) still gets its errors as
/// JSON. Dio hands that JSON over as bytes; the error's code must not be
/// lost on the way.
void main() {
  List<int> jsonBytes(Object body) => utf8.encode(jsonEncode(body));

  Map<String, dynamic> envelope(String code, String message) => {
    'success': false,
    'error': {'code': code, 'message': message},
  };

  group('ApiError.tryParse on a body that came as bytes', () {
    test('reads the code and message of a JSON error', () {
      final error = ApiError.tryParse(
        jsonBytes(envelope('NOT_FOUND', 'Payslip not found')),
      );

      expect(error?.code, 'NOT_FOUND');
      expect(error?.message, 'Payslip not found');
    });

    test('reads it from a Uint8List too', () {
      final error = ApiError.tryParse(
        Uint8List.fromList(jsonBytes(envelope('INTERNAL_ERROR', 'boom'))),
      );

      expect(error?.code, 'INTERNAL_ERROR');
    });

    test('reads Lao text as UTF-8', () {
      final error = ApiError.tryParse(
        jsonBytes(envelope('NOT_FOUND', 'ບໍ່ພົບ')),
      );

      expect(error?.message, 'ບໍ່ພົບ');
    });

    test('bytes that are not JSON (a PDF, an HTML page) are no error', () {
      expect(ApiError.tryParse(utf8.encode('%PDF-1.7 ...')), isNull);
      expect(ApiError.tryParse(utf8.encode('<html>502</html>')), isNull);
      expect(ApiError.tryParse(<int>[0xff, 0xfe, 0x00]), isNull);
      expect(ApiError.tryParse(<int>[]), isNull);
    });

    test('a code or message that is not text is left out, not a crash', () {
      final error = ApiError.tryParse({
        'success': false,
        'error': {'code': 5, 'message': 'odd'},
      });

      expect(error?.code, isNull);
      expect(error?.message, 'odd');
      expect(
        ApiError.tryParse({
          'error': {'code': 'X', 'message': 7},
          'message': 8,
        })?.message,
        isNull,
      );
    });

    test('JSON that is not an object is no error', () {
      expect(ApiError.tryParse(utf8.encode('[1, 2]')), isNull);
      expect(ApiError.tryParse(utf8.encode('"text"')), isNull);
    });
  });

  group('ApiErrorMapper on a bytes call', () {
    DioException refused(int status, Object body) => DioException(
      requestOptions: RequestOptions(path: '/payroll/payslips/my/p/pdf'),
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: RequestOptions(path: '/payroll/payslips/my/p/pdf'),
        statusCode: status,
        data: jsonBytes(body),
      ),
    );

    test('403 MODULE_NOT_ACTIVE keeps its code', () {
      final failure = ApiErrorMapper.fromDioException(
        refused(403, envelope(ApiErrorCodes.moduleNotActive, 'off')),
      );

      expect(failure, isA<ValidationFailure>());
      expect(
        (failure as ValidationFailure).code,
        ApiErrorCodes.moduleNotActive,
      );
    });

    test('404 keeps its status and the server\'s message', () {
      final failure = ApiErrorMapper.fromDioException(
        refused(404, envelope('NOT_FOUND', 'Payslip not found')),
      );

      expect(failure, isA<NetworkFailure>());
      expect((failure as NetworkFailure).statusCode, 404);
      expect(failure.errorCode, 'NOT_FOUND');
    });

    test('500 INTERNAL_ERROR keeps its code', () {
      final failure = ApiErrorMapper.fromDioException(
        refused(500, envelope('INTERNAL_ERROR', 'could not render')),
      );

      expect(failure, isA<ServerFailure>());
      expect((failure as ServerFailure).errorCode, 'INTERNAL_ERROR');
      expect(failure.message, 'could not render');
    });
  });
}
