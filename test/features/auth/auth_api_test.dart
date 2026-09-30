import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/exceptions.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/network/api_error_mapper.dart';
import 'package:next_on/core/network/api_response.dart';
import 'package:next_on/features/auth/data/models/login_response_model.dart';
import 'package:next_on/features/auth/data/models/user_model.dart';
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
  group('ApiEnvelope', () {
    test('unwraps the standard success envelope', () {
      final data = ApiEnvelope.unwrapObject({
        'success': true,
        'data': {'id': 'abc'},
      });

      expect(data['id'], 'abc');
    });

    test('tolerates a flat body', () {
      expect(ApiEnvelope.unwrapObject({'id': 'abc'})['id'], 'abc');
    });

    test('refuses to read an error envelope as data', () {
      expect(
        () => ApiEnvelope.unwrapObject({
          'success': false,
          'error': {'code': 'INVALID_CREDENTIALS'},
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });

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

  group('LoginResponseModel', () {
    test('reads the token pair and the expiry', () {
      final model = LoginResponseModel.fromJson({
        'access_token': 'access',
        'refresh_token': 'refresh',
        'expires_at': 1773504662,
        'must_change_password': true,
      });

      expect(model.accessToken, 'access');
      expect(model.refreshToken, 'refresh');
      expect(model.mustChangePassword, isTrue);
      expect(
        model.expiresAt,
        DateTime.fromMillisecondsSinceEpoch(1773504662 * 1000, isUtc: true),
      );
    });

    test('treats a missing or unusable expires_at as unknown', () {
      for (final value in const [null, 0, -1, 'later', '']) {
        final model = LoginResponseModel.fromJson({
          'access_token': 'access',
          'refresh_token': 'refresh',
          'expires_at': value,
        });

        expect(model.expiresAt, isNull, reason: 'expires_at: \$value');
        // An unknown expiry must never read as an expired one.
        expect(model.isExpired, isFalse, reason: 'expires_at: \$value');
      }
    });

    test('reads an expires_at sent as a numeric string', () {
      final model = LoginResponseModel.fromJson({
        'access_token': 'access',
        'refresh_token': 'refresh',
        'expires_at': '1773504662',
      });

      expect(
        model.expiresAt,
        DateTime.fromMillisecondsSinceEpoch(1773504662 * 1000, isUtc: true),
      );
    });

    test('isExpired tracks the clock', () {
      final past = LoginResponseModel.fromJson({
        'access_token': 'a',
        'refresh_token': 'r',
        'expires_at':
            DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000 - 60,
      });
      final future = LoginResponseModel.fromJson({
        'access_token': 'a',
        'refresh_token': 'r',
        'expires_at':
            DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000 + 3600,
      });

      expect(past.isExpired, isTrue);
      expect(future.isExpired, isFalse);
    });

    test('fails loudly when a token is missing', () {
      expect(
        () => LoginResponseModel.fromJson({'access_token': 'access'}),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('UserModel', () {
    test('maps the /auth/me payload', () {
      final user = UserModel.fromJson({
        'id': 'cce14a0e',
        'user_id': 'cce14a0e',
        'tenant_id': 'cbc6553a',
        'email': 'somphone.vilaysone@nexton.la',
        'first_name': 'Somphone',
        'last_name': 'Vilaysone',
        'roles': ['employee', 'team_lead'],
        'modules': ['core_hr', 'payroll'],
        'permissions': ['corehr:employee:read'],
        'employee_id': 'b3f1-employees-uuid',
      }).toEntity();

      expect(user.displayName, 'Somphone Vilaysone');
      expect(user.hasRole('team_lead'), isTrue);
      expect(user.hasModule('payroll'), isTrue);
      expect(user.hasPermission('corehr:employee:read'), isTrue);
      expect(user.employeeId, 'b3f1-employees-uuid');
      // Never sent by /auth/me.
      expect(user.profilePhotoUrl, isNull);
    });

    test('survives a null employee_id and missing arrays', () {
      final user = UserModel.fromJson({
        'id': 'cce14a0e',
        'tenant_id': 'cbc6553a',
        'email': 'a@b.la',
        'first_name': 'A',
        'last_name': 'B',
        'employee_id': null,
      }).toEntity();

      expect(user.employeeId, isNull);
      expect(user.roles, isEmpty);
      expect(user.permissions, isEmpty);
      expect(user.modules, isEmpty);
    });
  });
}
