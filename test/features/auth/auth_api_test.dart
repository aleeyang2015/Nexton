import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/exceptions.dart';
import 'package:next_on/core/network/api_response.dart';
import 'package:next_on/features/auth/data/models/login_response_model.dart';
import 'package:next_on/features/auth/data/models/user_model.dart';

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
