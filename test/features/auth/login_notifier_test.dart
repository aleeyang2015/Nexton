import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/auth/auth_providers.dart';
import 'package:next_on/features/auth/domain/entities/auth_session.dart';
import 'package:next_on/features/auth/presentation/providers/login_notifier.dart';
import 'package:next_on/features/auth/presentation/providers/login_state.dart';

import '../../support/auth_test_doubles.dart';

void main() {
  late FakeAuthRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeAuthRepository();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    // Keep the form provider alive across the test.
    container.listen(loginNotifierProvider, (_, __) {});
  });

  tearDown(() {
    container.dispose();
    repository.sessionExpired.close();
  });

  LoginNotifier notifier() => container.read(loginNotifierProvider.notifier);

  LoginState state() => container.read(loginNotifierProvider);

  Future<void> fillAndSubmit({
    String email = 'somphone.vilaysone@nexton.la',
    String password = 'password1',
  }) async {
    notifier()
      ..emailChanged(email)
      ..passwordChanged(password);
    await notifier().submit();
  }

  group('client-side validation', () {
    test('an empty email is reported on the email field', () async {
      await fillAndSubmit(email: '');

      expect(state().emailError, isNotNull);
      expect(state().passwordError, isNull);
      // The typed password is untouched by a form error.
      expect(state().password, 'password1');
      expect(state().passwordClearTick, 0);
    });

    test('a malformed email is reported on the email field', () async {
      await fillAndSubmit(email: 'not-an-email');

      expect(state().emailError, isNotNull);
    });

    test('a short password is reported on the password field', () async {
      await fillAndSubmit(password: 'short');

      expect(state().passwordError, contains('8'));
      expect(state().passwordClearTick, 0);
    });
  });

  group('submission', () {
    test('a successful login carries the session back to the page', () async {
      repository.loginResult = Result.success(AuthSession.signedIn(testUser()));

      await fillAndSubmit();

      expect(state().session!.status, AuthStatus.authenticated);
      expect(state().isSubmitting, isFalse);
    });

    test('must_change_password comes through on the submission', () async {
      repository.loginResult = Result.success(
        AuthSession.signedIn(testUser(), mustChangePassword: true),
      );

      await fillAndSubmit();

      expect(state().session!.mustChangePassword, isTrue);
    });

    test('invalid credentials clear the password field', () async {
      repository.loginResult = const Result.failure(
        Failure.auth(
          message: 'Invalid email or password',
          code: 'INVALID_CREDENTIALS',
        ),
      );

      await fillAndSubmit();

      expect(state().submission.hasError, isTrue);
      expect(state().password, isEmpty);
      expect(state().passwordClearTick, 1);
      // The email is left so the user only re-types the secret.
      expect(state().email, 'somphone.vilaysone@nexton.la');
    });

    test('a 429 throttle keeps the typed password', () async {
      repository.loginResult = const Result.failure(
        Failure.network(
          message: 'Too many attempts',
          statusCode: 429,
          errorCode: 'TOO_MANY_LOGIN_ATTEMPTS',
        ),
      );

      await fillAndSubmit();

      expect(state().submission.hasError, isTrue);
      expect(state().password, 'password1');
      expect(state().passwordClearTick, 0);
    });

    test('an offline attempt keeps the typed password', () async {
      repository.loginResult = const Result.failure(
        Failure.network(message: 'No internet connection'),
      );

      await fillAndSubmit();

      expect(state().password, 'password1');
      expect(state().passwordClearTick, 0);
    });

    test('a 422 marks the field the backend named', () async {
      repository.loginResult = const Result.failure(
        Failure.validation(
          message: 'The email field is required.',
          field: 'email',
        ),
      );

      await fillAndSubmit();

      expect(state().emailError, 'The email field is required.');
    });
  });

  group('form controls', () {
    test('toggles password visibility and remember-me', () {
      expect(state().obscurePassword, isTrue);
      notifier().togglePasswordVisibility();
      expect(state().obscurePassword, isFalse);

      expect(state().rememberMe, isFalse);
      notifier().toggleRememberMe();
      expect(state().rememberMe, isTrue);
    });

    test('typing clears the field error', () async {
      await fillAndSubmit(email: '');
      expect(state().emailError, isNotNull);

      notifier().emailChanged('a@b.la');
      expect(state().emailError, isNull);
    });
  });
}
