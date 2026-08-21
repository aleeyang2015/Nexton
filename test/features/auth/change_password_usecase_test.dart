import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/auth/domain/usecases/change_password_usecase.dart';

import '../../support/auth_test_doubles.dart';

ValidationFailure? _validate(String current, String next, String confirm) {
  final result = ChangePasswordParams(
    currentPassword: current,
    newPassword: next,
    confirmPassword: confirm,
  ).validate();

  return result.failureOrNull as ValidationFailure?;
}

void main() {
  group('ChangePasswordParams.validate — auth.md rule order', () {
    test('rule 1: an empty current password is reported first', () {
      // Every other rule is also broken here; rule 1 still wins.
      final failure = _validate('', 'short', 'mismatch');

      expect(failure, isNotNull);
      expect(failure!.field, ChangePasswordFields.current);
    });

    test('rule 2: a new password under 8 characters', () {
      final failure = _validate('current-pass', 'short', 'nope');

      expect(failure!.field, ChangePasswordFields.next);
      expect(failure.message, contains('8'));
    });

    test('rule 2 outranks rule 4', () {
      // Too short AND unconfirmed — the length message is the one shown.
      final failure = _validate('current-pass', 'short', 'different');

      expect(failure!.field, ChangePasswordFields.next);
    });

    test('rule 3: the new password must differ from the current one', () {
      final failure = _validate(
        'same-password',
        'same-password',
        'same-password',
      );

      expect(failure!.field, ChangePasswordFields.next);
      expect(failure.message, isNot(contains('8')));
    });

    test('rule 4: the confirmation must match', () {
      final failure = _validate('current-pass', 'new-password', 'new-passwrd');

      expect(failure!.field, ChangePasswordFields.confirm);
    });

    test('accepts a valid trio', () {
      expect(_validate('current-pass', 'new-password', 'new-password'), isNull);
    });

    test('exactly 8 characters passes — matches the backend length rule', () {
      expect(_validate('current-pass', '12345678', '12345678'), isNull);
    });
  });

  group('ChangePasswordUseCase', () {
    test('never calls the API when validation fails', () async {
      final repository = FakeAuthRepository();

      final result = await ChangePasswordUseCase(repository)(
        ChangePasswordParams(
          currentPassword: 'current-pass',
          newPassword: 'short',
          confirmPassword: 'short',
        ),
      );

      expect(result.isFailure, isTrue);
      expect(repository.changePasswordCalls, 0);
    });

    test('forwards a valid change to the repository', () async {
      final repository = FakeAuthRepository();

      final result = await ChangePasswordUseCase(repository)(
        ChangePasswordParams(
          currentPassword: 'current-pass',
          newPassword: 'new-password',
          confirmPassword: 'new-password',
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(repository.changePasswordCalls, 1);
    });

    test('surfaces a server rejection as a failure', () async {
      final repository = FakeAuthRepository()
        ..changePasswordResult = const Result.failure(
          Failure.auth(message: 'Wrong password', code: 'PASSWORD_MISMATCH'),
        );

      final result = await ChangePasswordUseCase(repository)(
        ChangePasswordParams(
          currentPassword: 'wrong-pass',
          newPassword: 'new-password',
          confirmPassword: 'new-password',
        ),
      );

      expect(result.failureOrNull, isA<AuthFailure>());
    });
  });
}
