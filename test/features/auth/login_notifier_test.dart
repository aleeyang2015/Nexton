import 'dart:ui';

import 'package:fake_async/fake_async.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:next_on/features/auth/data/datasources/remembered_email_store.dart';
import 'package:next_on/core/network/network_providers.dart';
import 'package:next_on/core/constants/app_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/l10n/failure_localizer.dart';
import 'package:next_on/core/errors/validation_codes.dart';
import 'package:next_on/core/utils/clock_provider.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/auth/auth_providers.dart';
import 'package:next_on/features/auth/domain/entities/auth_session.dart';
import 'package:next_on/features/auth/presentation/providers/login_notifier.dart';
import 'package:next_on/features/auth/presentation/providers/login_state.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';

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

      expect(state().passwordError, ValidationCode.passwordTooShort);
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

    test('a switched-off company clears the password and says so in Lao', () async {
      repository.loginResult = const Result.failure(
        Failure.auth(message: 'Tenant is not active', code: 'TENANT_INACTIVE'),
      );

      await fillAndSubmit();

      expect(state().password, isEmpty);
      expect(state().passwordClearTick, 1);
      final failure = state().submission.error! as Failure;
      expect(
        failure.localize(lookupAppLocalizations(const Locale('lo'))),
        'ບໍລິສັດຂອງທ່ານຖືກປິດການໃຊ້ງານ. ກະລຸນາຕິດຕໍ່ HR.',
      );
    });

    test('a 429 throttle with no Retry-After keeps the typed password and '
        'surfaces once, as before', () async {
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
      // Nothing to count down, so nothing holds the button.
      expect(state().isWaiting, isFalse);

      await notifier().submit();
      expect(repository.loginCalls, 2);
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

  group('the login throttle says how long to wait', () {
    final start = DateTime(2026, 11, 16, 9);

    Failure throttled(int seconds) => Failure.network(
      message: 'Too many attempts',
      statusCode: 429,
      errorCode: 'TOO_MANY_LOGIN_ATTEMPTS',
      retryAfter: Duration(seconds: seconds),
    );

    /// Runs [body] with fake timers and a clock that moves with them.
    void withClock(
      void Function(
        FakeAsync async,
        FakeAuthRepository repository,
        LoginNotifier notifier,
        LoginState Function() state,
      )
      body,
    ) {
      fakeAsync((async) {
        final repository = FakeAuthRepository();
        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(repository),
            clockProvider.overrideWithValue(() => start.add(async.elapsed)),
          ],
        );
        container.listen(loginNotifierProvider, (_, _) {});
        async.flushMicrotasks();

        final notifier = container.read(loginNotifierProvider.notifier)
          ..emailChanged('somphone.vilaysone@nexton.la')
          ..passwordChanged('password1');

        body(
          async,
          repository,
          notifier,
          () => container.read(loginNotifierProvider),
        );

        container.dispose();
        repository.sessionExpired.close();
        // Disposing cancelled the wait; nothing is left ticking.
        expect(async.pendingTimers, isEmpty);
      });
    }

    test('600 s sets retryAt, keeps the password, raises no error, and a '
        'second submit sends nothing', () {
      withClock((async, repository, notifier, state) {
        repository.loginResult = Result.failure(throttled(600));

        notifier.submit();
        async.flushMicrotasks();

        expect(state().retryAt, start.add(const Duration(minutes: 10)));
        expect(state().isWaiting, isTrue);
        expect(state().waitMinutesLeft, 10);
        expect(state().password, 'password1');
        expect(state().passwordClearTick, 0);
        // The line under the button says it; no toast on top.
        expect(state().submission.hasError, isFalse);
        expect(state().isSubmitting, isFalse);
        expect(repository.loginCalls, 1);

        notifier.submit();
        async.flushMicrotasks();

        expect(repository.loginCalls, 1);
      });
    });

    test('the minutes count down, and submit works again once the time '
        'has passed', () {
      withClock((async, repository, notifier, state) {
        repository.loginResult = Result.failure(throttled(600));
        notifier.submit();
        async.flushMicrotasks();

        async.elapse(const Duration(minutes: 1));
        expect(state().waitMinutesLeft, 9);

        async.elapse(const Duration(minutes: 8, seconds: 59));
        expect(state().isWaiting, isTrue);
        expect(state().waitMinutesLeft, 1);

        async.elapse(const Duration(seconds: 1));
        expect(state().isWaiting, isFalse);
        expect(state().retryAt, isNull);
        expect(state().waitMinutesLeft, 0);

        repository.loginResult = Result.success(
          AuthSession.signedIn(testUser()),
        );
        notifier.submit();
        async.flushMicrotasks();

        expect(repository.loginCalls, 2);
        expect(state().session, isNotNull);
      });
    });

    test('minutes round up and never read 0: 61 s is 2, 30 s is 1', () {
      withClock((async, repository, notifier, state) {
        repository.loginResult = Result.failure(throttled(61));
        notifier.submit();
        async.flushMicrotasks();
        expect(state().waitMinutesLeft, 2);

        async.elapse(const Duration(seconds: 1));
        expect(state().waitMinutesLeft, 1);

        async.elapse(const Duration(seconds: 59));
        expect(state().isWaiting, isTrue);
        async.elapse(const Duration(seconds: 1));
        expect(state().isWaiting, isFalse);
      });

      withClock((async, repository, notifier, state) {
        repository.loginResult = Result.failure(throttled(30));
        notifier.submit();
        async.flushMicrotasks();
        expect(state().waitMinutesLeft, 1);
      });
    });

    test('a timer that fired late does not hold the user back', () {
      // The phone slept through the wait: the clock is past retryAt but no
      // timer has run.
      var now = start;
      final repository = FakeAuthRepository()
        ..loginResult = Result.failure(throttled(600));
      fakeAsync((async) {
        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(repository),
            clockProvider.overrideWithValue(() => now),
          ],
        );
        container.listen(loginNotifierProvider, (_, _) {});
        final notifier = container.read(loginNotifierProvider.notifier)
          ..emailChanged('somphone.vilaysone@nexton.la')
          ..passwordChanged('password1');

        notifier.submit();
        async.flushMicrotasks();
        expect(container.read(loginNotifierProvider).isWaiting, isTrue);

        now = start.add(const Duration(minutes: 11));
        notifier.submit();
        async.flushMicrotasks();

        expect(repository.loginCalls, 2);

        container.dispose();
        repository.sessionExpired.close();
      });
    });

    test('only the login throttle starts a wait: another failure with a '
        'Retry-After surfaces as an error', () {
      withClock((async, repository, notifier, state) {
        for (final failure in const [
          Failure.network(
            message: 'slow down',
            statusCode: 429,
            errorCode: 'RATE_LIMITED',
            retryAfter: Duration(seconds: 120),
          ),
          Failure.network(
            message: 'no such company',
            statusCode: 404,
            errorCode: 'TENANT_NOT_FOUND',
            retryAfter: Duration(seconds: 120),
          ),
        ]) {
          repository.loginResult = Result.failure(failure);
          notifier.submit();
          async.flushMicrotasks();

          expect(state().isWaiting, isFalse);
          expect(state().submission.hasError, isTrue);
        }
        expect(async.pendingTimers, isEmpty);
      });
    });

    test('an enormous Retry-After is held to an hour, and the form does not '
        'hang', () {
      withClock((async, repository, notifier, state) {
        repository.loginResult = Result.failure(throttled(9000000000000));
        notifier.submit();
        async.flushMicrotasks();

        expect(state().isSubmitting, isFalse);
        expect(state().waitMinutesLeft, 60);
        expect(state().retryAt, start.add(const Duration(hours: 1)));

        async.elapse(const Duration(hours: 1));
        expect(state().isWaiting, isFalse);
      });
    });

    test('coming back to the App after the wait ran out ends it at once', () {
      var now = start;
      final repository = FakeAuthRepository()
        ..loginResult = Result.failure(throttled(600));
      fakeAsync((async) {
        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(repository),
            clockProvider.overrideWithValue(() => now),
          ],
        );
        container.listen(loginNotifierProvider, (_, _) {});
        final notifier = container.read(loginNotifierProvider.notifier)
          ..emailChanged('somphone.vilaysone@nexton.la')
          ..passwordChanged('password1')
          ..submit();
        async.flushMicrotasks();

        // The phone slept: the clock moved on, no timer ran.
        now = start.add(const Duration(minutes: 30));
        expect(container.read(loginNotifierProvider).isWaiting, isTrue);

        notifier.syncWait();

        expect(container.read(loginNotifierProvider).isWaiting, isFalse);
        expect(async.pendingTimers, isEmpty);

        container.dispose();
        repository.sessionExpired.close();
      });
    });

    test('a device clock set back cannot stretch the wait', () {
      var skew = Duration.zero;
      final repository = FakeAuthRepository()
        ..loginResult = Result.failure(throttled(600));
      fakeAsync((async) {
        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(repository),
            clockProvider.overrideWithValue(
              () => start.add(async.elapsed).add(skew),
            ),
          ],
        );
        container.listen(loginNotifierProvider, (_, _) {});
        LoginState state() => container.read(loginNotifierProvider);
        container.read(loginNotifierProvider.notifier)
          ..emailChanged('somphone.vilaysone@nexton.la')
          ..passwordChanged('password1')
          ..submit();
        async.flushMicrotasks();
        expect(state().waitMinutesLeft, 10);

        skew = const Duration(days: -1);

        async.elapse(const Duration(minutes: 1));
        expect(state().waitMinutesLeft, 9);

        // Ten real minutes after the answer, the wait is over.
        async.elapse(const Duration(minutes: 9));
        expect(state().isWaiting, isFalse);
        expect(async.pendingTimers, isEmpty);

        container.dispose();
        repository.sessionExpired.close();
      });
    });

    test('a second throttle restarts the wait from the new answer', () {
      withClock((async, repository, notifier, state) {
        repository.loginResult = Result.failure(throttled(60));
        notifier.submit();
        async.flushMicrotasks();

        async.elapse(const Duration(seconds: 60));
        expect(state().isWaiting, isFalse);

        repository.loginResult = Result.failure(throttled(300));
        notifier.submit();
        async.flushMicrotasks();

        expect(state().waitMinutesLeft, 5);
        expect(async.pendingTimers, hasLength(1));
      });
    });
  });

  group('remember my email (#60)', () {
    late SharedPreferences prefs;
    late ProviderContainer c;
    late ProviderSubscription<LoginState> form;

    Future<void> open({Map<String, Object> saved = const {}}) async {
      SharedPreferences.setMockInitialValues(saved);
      prefs = await SharedPreferences.getInstance();
      c = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(c.dispose);
      form = c.listen(loginNotifierProvider, (_, _) {});
    }

    LoginNotifier n() => c.read(loginNotifierProvider.notifier);
    LoginState s() => c.read(loginNotifierProvider);
    String? savedEmail() => prefs.getString(AppConstants.rememberedEmailKey);

    void signInSucceeds() => repository.loginResult = Result.success(
      AuthSession.signedIn(testUser()),
    );

    test('a saved email: the form starts with it, the box ticked', () async {
      await open(saved: {AppConstants.rememberedEmailKey: 'noy.s@shop.la'});
      expect(s().email, 'noy.s@shop.la');
      expect(s().rememberMe, isTrue);
    });

    test('nothing saved: empty, the box unticked', () async {
      await open();
      expect(s().email, isEmpty);
      expect(s().rememberMe, isFalse);
    });

    test('ticked and signed in: the email (trimmed) is kept, even though the '
        'form is disposed during the sign-in', () async {
      await open();
      signInSucceeds();
      // The router leaves /login as the session flips: the form goes.
      repository.whileLoggingIn = () async {
        form.close();
        // Riverpod drops the unwatched form a moment later: let it.
        await pumpEventQueue();
      };
      n()
        ..emailChanged('  noy.s@shop.la ')
        ..passwordChanged('password1')
        ..toggleRememberMe();

      final notifier = n();
      await notifier.submit();
      await pumpEventQueue();

      // Really gone during the sign-in, as on the phone.
      expect(c.exists(loginNotifierProvider), isFalse);
      expect(savedEmail(), 'noy.s@shop.la');
    });

    test('unticked and signed in: the saved email is forgotten', () async {
      await open(saved: {AppConstants.rememberedEmailKey: 'noy.s@shop.la'});
      signInSucceeds();
      n()
        ..passwordChanged('password1')
        ..toggleRememberMe();
      expect(s().rememberMe, isFalse);

      await n().submit();
      await pumpEventQueue();

      expect(savedEmail(), isNull);
    });

    test('the box cannot change while a sign-in is on its way: what is '
        'saved is what was sent', () async {
      await open();
      signInSucceeds();
      n()
        ..emailChanged('noy.s@shop.la')
        ..passwordChanged('password1')
        ..toggleRememberMe();
      repository.whileLoggingIn = () async {
        // Unticked mid-flight: held.
        n().toggleRememberMe();
        expect(s().rememberMe, isTrue);
      };

      await n().submit();
      await pumpEventQueue();
      expect(savedEmail(), 'noy.s@shop.la');
    });

    test('a wrong password, ticked: nothing new is saved', () async {
      await open(saved: {AppConstants.rememberedEmailKey: 'old@shop.la'});
      repository.loginResult = const Result.failure(
        Failure.auth(message: 'Invalid email or password'),
      );
      n()
        ..emailChanged('new@shop.la')
        ..passwordChanged('wrong-one');

      await n().submit();
      await pumpEventQueue();

      expect(savedEmail(), 'old@shop.la');
    });

    test('a failure, unticked: the saved email stays too', () async {
      await open(saved: {AppConstants.rememberedEmailKey: 'old@shop.la'});
      repository.loginResult = const Result.failure(
        Failure.network(message: 'No internet connection'),
      );
      n()
        ..passwordChanged('password1')
        ..toggleRememberMe();

      await n().submit();
      await pumpEventQueue();

      expect(savedEmail(), 'old@shop.la');
    });

    test('no store at all (no preferences): the login still works', () async {
      // The suite's own container has no SharedPreferences.
      repository.loginResult = Result.success(AuthSession.signedIn(testUser()));
      notifier()
        ..emailChanged('noy.s@shop.la')
        ..passwordChanged('password1')
        ..toggleRememberMe();
      await notifier().submit();
      expect(state().session, isNotNull);
    });

    test('a store that fails to save does not break the login', () async {
      c = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          rememberedEmailStoreProvider.overrideWithValue(_FailingStore()),
        ],
      );
      addTearDown(c.dispose);
      c.listen(loginNotifierProvider, (_, _) {});
      signInSucceeds();
      n()
        ..emailChanged('noy.s@shop.la')
        ..passwordChanged('password1')
        ..toggleRememberMe();

      await n().submit();
      expect(s().session, isNotNull);
    });
  });
}

/// A store whose phone storage refuses every write.
class _FailingStore extends RememberedEmailStore {
  _FailingStore() : super(_ThrowingPrefs());
}

class _ThrowingPrefs implements SharedPreferences {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw Exception('disk full');
}
