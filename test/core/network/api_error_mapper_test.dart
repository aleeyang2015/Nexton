import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/network/api_error_mapper.dart';
import 'package:next_on/features/auth/domain/auth_failure_x.dart';

DioException _badResponse(
  int status,
  dynamic body, {
  Map<String, List<String>>? headers,
}) => DioException(
  requestOptions: RequestOptions(path: '/auth/login'),
  type: DioExceptionType.badResponse,
  response: Response(
    requestOptions: RequestOptions(path: '/auth/login'),
    statusCode: status,
    data: body,
    headers: headers == null ? null : Headers.fromMap(headers),
  ),
);

/// A throttled login, with whatever `Retry-After` the server chose to send.
DioException _throttled({Map<String, List<String>>? headers}) => _badResponse(
  429,
  {
    'success': false,
    'error': {
      'code': 'TOO_MANY_LOGIN_ATTEMPTS',
      'message': 'Too many attempts',
    },
  },
  headers: headers,
);

void main() {
  group('ApiErrorMapper', () {
    test('401 INVALID_CREDENTIALS is a credential failure', () {
      final failure = ApiErrorMapper.fromDioException(
        _badResponse(401, {
          'success': false,
          'error': {
            'code': 'INVALID_CREDENTIALS',
            'message': 'Invalid email or password',
          },
        }),
      );

      expect(failure, isA<AuthFailure>());
      expect(failure.message, 'Invalid email or password');
      expect(failure.isCredentialFailure, isTrue);
    });

    test(
      '400 PASSWORD_MISMATCH is a credential failure, not a bad request',
      () {
        final failure = ApiErrorMapper.fromDioException(
          _badResponse(400, {
            'success': false,
            'error': {'code': 'PASSWORD_MISMATCH', 'message': 'Wrong password'},
          }),
        );

        expect(failure, isA<AuthFailure>());
        expect(failure.isCredentialFailure, isTrue);
      },
    );

    test('422 carries the offending field', () {
      final failure = ApiErrorMapper.fromDioException(
        _badResponse(422, {
          'success': false,
          'message': 'The given data was invalid.',
          'errors': {
            'email': ['The email field is required.'],
          },
        }),
      );

      expect(failure, isA<ValidationFailure>());
      expect((failure as ValidationFailure).field, 'email');
    });

    test('429 login throttle is NOT a credential failure', () {
      final failure = ApiErrorMapper.fromDioException(
        _badResponse(429, {
          'success': false,
          'error': {
            'code': 'TOO_MANY_LOGIN_ATTEMPTS',
            'message': 'Too many attempts',
          },
        }),
      );

      expect(failure, isA<NetworkFailure>());
      expect(failure.isCredentialFailure, isFalse);
      expect(failure.message, 'Too many attempts');
    });

    test('429 carries the Retry-After the server asked for', () {
      final failure = ApiErrorMapper.fromDioException(
        _throttled(headers: {'retry-after': ['45']}),
      );

      expect(failure, isA<NetworkFailure>());
      expect((failure as NetworkFailure).retryAfter, const Duration(seconds: 45));
      // Reachable without matching on the variant.
      expect(failure.retryAfter, const Duration(seconds: 45));
      // Still not a credential failure: the typed password must survive.
      expect(failure.isCredentialFailure, isFalse);
    });

    test('a throttle with no Retry-After leaves the delay unknown', () {
      final failure = ApiErrorMapper.fromDioException(_throttled());

      expect(failure.retryAfter, isNull);
    });

    test('an unusable Retry-After is unknown, never a zero wait', () {
      // An HTTP-date (RFC 9110's other form), junk, zero and a negative value
      // must all read as "the server did not say" rather than "retry now".
      for (final raw in const [
        'Wed, 21 Oct 2026 07:28:00 GMT',
        'soon',
        '',
        '0',
        '-30',
      ]) {
        final failure = ApiErrorMapper.fromDioException(
          _throttled(headers: {'retry-after': [raw]}),
        );

        expect(failure.retryAfter, isNull, reason: 'Retry-After: "\$raw"');
      }
    });

    test('Retry-After is read case-insensitively', () {
      final failure = ApiErrorMapper.fromDioException(
        _throttled(headers: {'Retry-After': ['15']}),
      );

      expect(failure.retryAfter, const Duration(seconds: 15));
    });

    test('a failure that is not a throttle has no retryAfter', () {
      final failure = ApiErrorMapper.fromDioException(
        _badResponse(401, {
          'success': false,
          'error': {'code': 'INVALID_CREDENTIALS', 'message': 'nope'},
        }),
      );

      expect(failure, isA<AuthFailure>());
      expect(failure.retryAfter, isNull);
    });

    test('5xx is a server failure', () {
      final failure = ApiErrorMapper.fromDioException(
        _badResponse(500, {
          'success': false,
          'error': {'code': 'INTERNAL_ERROR', 'message': 'boom'},
        }),
      );

      expect(failure, isA<ServerFailure>());
    });
  });

  group('a refusal is not a lost session', () {
    Failure refused(int status, String code, {String message = 'refused'}) =>
        ApiErrorMapper.fromDioException(
          _badResponse(status, {
            'success': false,
            'error': {'code': code, 'message': message},
          }),
        );

    test('403 MODULE_NOT_ACTIVE is a validation failure with its code', () {
      final failure = refused(
        403,
        'MODULE_NOT_ACTIVE',
        message: "Module 'payroll' is not active for this subscription",
      );

      expect(failure, isA<ValidationFailure>());
      expect((failure as ValidationFailure).code, 'MODULE_NOT_ACTIVE');
      expect(
        failure.message,
        "Module 'payroll' is not active for this subscription",
      );
      expect(failure.isSessionFailure, isFalse);
    });

    test('403 NOT_APPROVER is a validation failure with its code', () {
      final failure = refused(403, 'NOT_APPROVER');

      expect(failure, isA<ValidationFailure>());
      expect((failure as ValidationFailure).code, 'NOT_APPROVER');
      expect(failure.isSessionFailure, isFalse);
    });

    test('a 403 with no code is still a refusal, not a sign-out', () {
      final failure = ApiErrorMapper.fromDioException(
        _badResponse(403, {'success': false}),
      );

      expect(failure, isA<ValidationFailure>());
      expect((failure as ValidationFailure).code, isNull);
    });

    test('403 USER_INACTIVE is an auth failure', () {
      final failure = refused(403, 'USER_INACTIVE');

      expect(failure, isA<AuthFailure>());
      expect((failure as AuthFailure).code, 'USER_INACTIVE');
    });

    test('403 TENANT_INACTIVE is an auth failure: the company is off', () {
      final failure = refused(403, 'TENANT_INACTIVE');

      expect(failure, isA<AuthFailure>());
      expect((failure as AuthFailure).code, 'TENANT_INACTIVE');
      expect(failure.isSessionFailure, isTrue);
    });

    test('401 INVALID_TOKEN is an auth failure', () {
      final failure = refused(401, 'INVALID_TOKEN');

      expect(failure, isA<AuthFailure>());
      expect(failure.isSessionFailure, isTrue);
    });

    test('400 SUBDOMAIN_REQUIRED stays an auth failure', () {
      expect(refused(400, 'SUBDOMAIN_REQUIRED'), isA<AuthFailure>());
    });

    test('a 400 keeps its code', () {
      final failure = refused(400, 'EMPLOYEE_NOT_FOUND');

      expect(failure, isA<ValidationFailure>());
      expect((failure as ValidationFailure).code, 'EMPLOYEE_NOT_FOUND');
    });

    test('a 422 keeps its code and its field', () {
      final failure = ApiErrorMapper.fromDioException(
        _badResponse(422, {
          'success': false,
          'error': {'code': 'VALIDATION_ERROR', 'message': 'Invalid data'},
          'errors': {
            'email': ['The email field is required.'],
          },
        }),
      );

      expect(failure, isA<ValidationFailure>());
      expect((failure as ValidationFailure).code, 'VALIDATION_ERROR');
      expect(failure.field, 'email');
    });

    test('404 TENANT_NOT_FOUND and 429 RATE_LIMITED keep their code', () {
      final notFound = refused(404, 'TENANT_NOT_FOUND');
      final limited = refused(429, 'RATE_LIMITED');

      expect((notFound as NetworkFailure).errorCode, 'TENANT_NOT_FOUND');
      expect((limited as NetworkFailure).errorCode, 'RATE_LIMITED');
    });

    test('503 TENANT_UNAVAILABLE is a server failure with its code', () {
      final failure = refused(503, 'TENANT_UNAVAILABLE');

      expect((failure as ServerFailure).errorCode, 'TENANT_UNAVAILABLE');
    });
  });
}
