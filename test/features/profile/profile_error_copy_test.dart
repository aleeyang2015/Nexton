import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/network/api_error_mapper.dart';
import 'package:next_on/features/profile/presentation/profile_error_copy.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';

void main() {
  final lo = lookupAppLocalizations(const Locale('lo'));
  final en = lookupAppLocalizations(const Locale('en'));

  const couldNotLoadLo = 'ບໍ່ສາມາດໂຫຼດໂປຣຟາຍໄດ້.';
  const couldNotLoadEn = 'Could not load your profile.';

  group('the rows of the table', () {
    test('400 EMPLOYEE_NOT_FOUND: the not-linked text, no Retry', () {
      const failure = Failure.validation(
        message: 'employee not found',
        code: 'EMPLOYEE_NOT_FOUND',
      );

      final copy = profileErrorCopy(lo, failure);

      expect(
        copy.text,
        'ບັນຊີຂອງທ່ານຍັງບໍ່ໄດ້ຜູກກັບຂໍ້ມູນພະນັກງານ. ກະລຸນາຕິດຕໍ່ HR.',
      );
      expect(copy.canRetry, isFalse);
      expect(
        profileErrorCopy(en, failure).text,
        'Your account is not linked to an employee record. '
        'Please contact HR.',
      );
    });

    test('403 MODULE_NOT_ACTIVE: its own text, no Retry', () {
      const failure = Failure.validation(
        message: "Module 'core_hr' is not active for this subscription",
        code: 'MODULE_NOT_ACTIVE',
      );

      final copy = profileErrorCopy(lo, failure);

      expect(copy.text, lo.errorModuleNotActive);
      expect(copy.canRetry, isFalse);
    });

    test('503 TENANT_UNAVAILABLE: its own text, with Retry', () {
      const failure = Failure.server(
        message: 'tenant database unavailable',
        statusCode: 503,
        errorCode: 'TENANT_UNAVAILABLE',
      );

      final copy = profileErrorCopy(lo, failure);

      expect(copy.text, lo.errorTenantUnavailable);
      expect(copy.canRetry, isTrue);
    });

    test('a 500 is "could not load your profile", with Retry: a database '
        'fault is never "not linked"', () {
      const failure = Failure.server(
        message: 'boom',
        statusCode: 500,
        errorCode: 'INTERNAL_ERROR',
      );

      expect(profileErrorCopy(lo, failure), (
        text: couldNotLoadLo,
        canRetry: true,
      ));
      expect(profileErrorCopy(en, failure).text, couldNotLoadEn);
    });

    test('no connection and a timeout are "could not load", with Retry', () {
      for (final failure in const [
        Failure.network(message: 'No internet connection', errorCode: 'NO_INTERNET'),
        Failure.network(message: 'Request timeout', errorCode: 'TIMEOUT'),
      ]) {
        expect(profileErrorCopy(lo, failure), (
          text: couldNotLoadLo,
          canRetry: true,
        ), reason: '$failure');
      }
    });
  });

  group('everything else', () {
    test('another 5xx, with or without a code, is "could not load" with '
        'Retry', () {
      for (final failure in const [
        Failure.server(message: 'bad gateway', statusCode: 502),
        Failure.server(
          message: 'odd',
          statusCode: 503,
          errorCode: 'SOMETHING_NEW',
        ),
      ]) {
        expect(profileErrorCopy(en, failure), (
          text: couldNotLoadEn,
          canRetry: true,
        ));
      }
    });

    test('503 TENANT_LOOKUP_FAILED shares the company-not-ready text', () {
      const failure = Failure.server(
        message: 'lookup failed',
        statusCode: 503,
        errorCode: 'TENANT_LOOKUP_FAILED',
      );

      expect(profileErrorCopy(lo, failure), (
        text: lo.errorTenantUnavailable,
        canRetry: true,
      ));
    });

    test('a coded refusal the App has no text for shows the server\'s '
        'message (the shared table\'s rule), and no Retry', () {
      const failure = Failure.validation(
        message: 'Profile is locked',
        code: 'PROFILE_LOCKED',
      );

      expect(profileErrorCopy(lo, failure), (
        text: 'Profile is locked',
        canRetry: false,
      ));
    });

    test('a 404 with the server\'s code is a verdict: its text, no Retry', () {
      const failure = Failure.network(
        message: 'Tenant subdomain is not registered',
        statusCode: 404,
        errorCode: 'TENANT_NOT_FOUND',
      );

      expect(profileErrorCopy(lo, failure), (
        text: lo.errorTenantNotFound,
        canRetry: false,
      ));
    });

    test('a session the server refused by code offers no Retry', () {
      const failure = Failure.auth(message: 'expired', code: 'INVALID_TOKEN');

      expect(profileErrorCopy(lo, failure), (
        text: lo.sessionExpired,
        canRetry: false,
      ));
    });

    test('a non-Failure error is "could not load" with Retry', () {
      expect(profileErrorCopy(en, StateError('odd')), (
        text: couldNotLoadEn,
        canRetry: true,
      ));
      expect(
        profileErrorCopy(en, const Failure.unknown(message: 'bad json')),
        (text: couldNotLoadEn, canRetry: true),
      );
    });
  });

  group('a failure with no code from the server can be retried, and never '
      'shows raw English', () {
    // What the real chain produces: `ApiErrorMapper` for a response, and
    // `BaseRepository` turning a `FormatException` into a validation failure.
    DioException response(int status, [Object? body, Map<String, List<String>>? headers]) =>
        DioException(
          requestOptions: RequestOptions(path: '/core_hr/employees/me'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/core_hr/employees/me'),
            statusCode: status,
            data: body,
            headers: headers == null ? null : Headers.fromMap(headers),
          ),
        );

    ({String text, bool canRetry}) copyFor(DioException error) =>
        profileErrorCopy(lo, ApiErrorMapper.fromDioException(error));

    test('a Wi-Fi sign-in page where JSON was expected', () {
      // `ApiEnvelope.unwrapObject` throws, and the repository maps it so.
      const failure = Failure.validation(
        message: 'Expected a JSON object response',
      );

      expect(profileErrorCopy(lo, failure), (
        text: couldNotLoadLo,
        canRetry: true,
      ));
    });

    test('a 403 or a 400 with an HTML body: a proxy answered, not the API', () {
      for (final status in const [400, 403]) {
        expect(
          copyFor(response(status, '<html>Forbidden</html>')),
          (text: couldNotLoadLo, canRetry: true),
          reason: '$status',
        );
      }
    });

    test('a 401 with no body', () {
      expect(copyFor(response(401)), (text: couldNotLoadLo, canRetry: true));
    });

    test('a 404 with no code', () {
      expect(copyFor(response(404, '<html>')), (
        text: couldNotLoadLo,
        canRetry: true,
      ));
    });

    test('a 408', () {
      expect(copyFor(response(408)), (text: couldNotLoadLo, canRetry: true));
    });

    test('a 429 keeps its "try again later" text, and can be retried', () {
      final limited = copyFor(
        response(429, {
          'success': false,
          'error': {'code': 'RATE_LIMITED', 'message': 'slow down'},
        }, {
          'retry-after': ['30'],
        }),
      );
      final bare = copyFor(response(429));

      expect(limited, (text: lo.errorRateLimited, canRetry: true));
      expect(bare.canRetry, isTrue);
      expect(bare.text, lo.tooManyAttempts);
    });

    test('a 502 with an HTML body, a timeout and no connection', () {
      expect(copyFor(response(502, '<html>Bad gateway</html>')), (
        text: couldNotLoadLo,
        canRetry: true,
      ));
      for (final type in const [
        DioExceptionType.receiveTimeout,
        DioExceptionType.connectionError,
      ]) {
        expect(
          copyFor(
            DioException(
              requestOptions: RequestOptions(path: '/core_hr/employees/me'),
              type: type,
            ),
          ),
          (text: couldNotLoadLo, canRetry: true),
        );
      }
    });

    test('the coded rows still arrive as refusals through the real mapper', () {
      Object coded(int status, String code) => {
        'success': false,
        'error': {'code': code, 'message': 'server english'},
      };

      expect(copyFor(response(400, coded(400, 'EMPLOYEE_NOT_FOUND'))), (
        text: lo.ruleEmployeeNotFound,
        canRetry: false,
      ));
      expect(copyFor(response(403, coded(403, 'MODULE_NOT_ACTIVE'))), (
        text: lo.errorModuleNotActive,
        canRetry: false,
      ));
      expect(copyFor(response(403, coded(403, 'FORBIDDEN'))), (
        text: lo.accessForbidden,
        canRetry: false,
      ));
      expect(copyFor(response(503, coded(503, 'TENANT_UNAVAILABLE'))), (
        text: lo.errorTenantUnavailable,
        canRetry: true,
      ));
      expect(copyFor(response(500, coded(500, 'INTERNAL_ERROR'))), (
        text: couldNotLoadLo,
        canRetry: true,
      ));
    });
  });
}
