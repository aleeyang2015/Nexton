import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/network/session_end_reason.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/auth/auth_providers.dart';
import 'package:next_on/features/auth/domain/entities/auth_session.dart';
import 'package:next_on/features/auth/domain/entities/user.dart';
import 'package:next_on/features/auth/presentation/providers/auth_session_notifier.dart';

import '../../support/auth_test_doubles.dart';

void main() {
  late FakeAuthRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeAuthRepository();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
  });

  tearDown(() {
    container.dispose();
    repository.sessionExpired.close();
  });

  Future<AuthSession> session() => container.read(authSessionProvider.future);

  AuthSession current() => container.read(authSessionProvider).requireValue;

  group('cold start', () {
    test('resolves to unauthenticated with no stored session', () async {
      expect((await session()).status, AuthStatus.unauthenticated);
    });

    test('a session the network layer gave up on mid-restore keeps its '
        'reason', () async {
      // /auth/me got a 401, the refresh was refused, and only then does the
      // restore answer, with a plain "unauthenticated".
      repository.whileRestoring = () async {
        repository.sessionExpired.add(SessionEndReason.accountDisabled);
        await Future<void>.delayed(Duration.zero);
      };

      final restored = await session();

      expect(restored.status, AuthStatus.unauthenticated);
      expect(restored.endReason, SessionEndReason.accountDisabled);
      expect(repository.logoutCalls, 1);
    });

    test('a restore that kept a cached identity still ends when the network '
        'layer gave up', () async {
      repository
        ..restoreResult = Result.success(AuthSession.signedIn(testUser()))
        ..whileRestoring = () async {
          repository.sessionExpired.add(SessionEndReason.expired);
          await Future<void>.delayed(Duration.zero);
        };

      final restored = await session();

      expect(restored.hasSession, isFalse);
      expect(restored.endReason, SessionEndReason.expired);
    });

    test('restores a full session', () async {
      repository.restoreResult = Result.success(
        AuthSession.signedIn(testUser()),
      );

      final restored = await session();

      expect(restored.status, AuthStatus.authenticated);
      expect(restored.user!.id, 'cce14a0e');
    });

    test('restores a session still owing a password change', () async {
      repository.restoreResult = Result.success(
        AuthSession.signedIn(testUser(), mustChangePassword: true),
      );

      expect((await session()).status, AuthStatus.mustChangePassword);
    });

    test('a failed restore falls back to unauthenticated', () async {
      repository.restoreResult = const Result.failure(
        Failure.network(message: 'No internet connection'),
      );

      expect((await session()).status, AuthStatus.unauthenticated);
    });
  });

  group('login', () {
    test('publishes an authenticated session', () async {
      await session();
      repository.loginResult = Result.success(AuthSession.signedIn(testUser()));

      final result = await container
          .read(authSessionProvider.notifier)
          .login(email: 'a@b.la', password: 'password1');

      expect(result.isSuccess, isTrue);
      expect(current().status, AuthStatus.authenticated);
    });

    test(
      'must_change_password: true pins the session to the change state',
      () async {
        await session();
        repository.loginResult = Result.success(
          AuthSession.signedIn(testUser(), mustChangePassword: true),
        );

        await container
            .read(authSessionProvider.notifier)
            .login(email: 'a@b.la', password: 'password1');

        expect(current().status, AuthStatus.mustChangePassword);
        expect(current().isAuthenticated, isFalse);
      },
    );

    test('a rejected login leaves the session alone', () async {
      await session();
      repository.loginResult = const Result.failure(
        Failure.auth(message: 'Invalid email or password'),
      );

      final result = await container
          .read(authSessionProvider.notifier)
          .login(email: 'a@b.la', password: 'wrong-password');

      expect(result.failureOrNull, isA<AuthFailure>());
      expect(current().status, AuthStatus.unauthenticated);
    });
  });

  group('changePassword', () {
    setUp(() {
      repository.restoreResult = Result.success(
        AuthSession.signedIn(testUser(), mustChangePassword: true),
      );
    });

    test('signs in again with the user\'s email and the new password', () async {
      await session();
      repository.loginResult = Result.success(
        AuthSession.signedIn(testUser(id: 'refreshed')),
      );

      final result = await container
          .read(authSessionProvider.notifier)
          .changePassword(
            currentPassword: 'current-pass',
            newPassword: 'new-password',
            confirmPassword: 'new-password',
          );

      expect(result.isSuccess, isTrue);
      // The old refresh token died with the change; this is what stores a
      // pair that still refreshes.
      expect(repository.loginCalls, 1);
      expect(repository.lastLoginEmail, 'somphone.vilaysone@nexton.la');
      expect(repository.lastLoginPassword, 'new-password');
      expect(current().status, AuthStatus.authenticated);
      expect(current().mustChangePassword, isFalse);
      expect(current().user!.id, 'refreshed');
      expect(current().endReason, isNull);
    });

    test('a failed re-login ends the session with passwordChanged', () async {
      await session();
      repository.loginResult = const Result.failure(
        Failure.network(message: 'No internet connection'),
      );

      final result = await container
          .read(authSessionProvider.notifier)
          .changePassword(
            currentPassword: 'current-pass',
            newPassword: 'new-password',
            confirmPassword: 'new-password',
          );

      // The change itself went through.
      expect(result.isSuccess, isTrue);
      expect(repository.logoutCalls, 1);
      expect(current().status, AuthStatus.unauthenticated);
      expect(current().endReason, SessionEndReason.passwordChanged);
    });

    test('a rejected change keeps the user on the hook', () async {
      await session();
      repository.changePasswordResult = const Result.failure(
        Failure.auth(message: 'Current password is wrong'),
      );

      final result = await container
          .read(authSessionProvider.notifier)
          .changePassword(
            currentPassword: 'nope',
            newPassword: 'new-password',
            confirmPassword: 'new-password',
          );

      expect(result.failureOrNull, isA<AuthFailure>());
      expect(current().status, AuthStatus.mustChangePassword);
      expect(repository.loginCalls, 0);
    });

    test('client-side validation never reaches the repository', () async {
      await session();

      final result = await container
          .read(authSessionProvider.notifier)
          .changePassword(
            currentPassword: 'current-pass',
            newPassword: 'short',
            confirmPassword: 'short',
          );

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(repository.changePasswordCalls, 0);
      expect(current().status, AuthStatus.mustChangePassword);
    });
  });

  group('back from the background: /auth/me read again', () {
    User head() => User(
      id: testUser().id,
      tenantId: testUser().tenantId,
      email: testUser().email,
      firstName: testUser().firstName,
      lastName: testUser().lastName,
      employeeId: testUser().employeeId,
      isDepartmentHead: true,
    );

    test('made a head meanwhile: the session shows it without a new sign-in',
        () async {
      repository.restoreResult = Result.success(AuthSession.signedIn(testUser()));
      await session();
      repository.profileResult = Result.success(head());

      await container.read(authSessionProvider.notifier).refreshOnResume();

      expect(current().user?.isDepartmentHead, isTrue);
      expect(current().status, AuthStatus.authenticated);
    });

    test('returning twice while one is on its way: one /auth/me', () async {
      repository.restoreResult = Result.success(AuthSession.signedIn(testUser()));
      await session();
      final slow = Completer<void>();
      repository.holdProfile = slow;
      final notifier = container.read(authSessionProvider.notifier);

      final first = notifier.refreshOnResume();
      await notifier.refreshOnResume();
      slow.complete();
      await first;
      await notifier.refreshOnResume();

      expect(repository.fetchProfileCalls, 2);
    });

    test('signed out: nothing is asked', () async {
      await session();

      await container.read(authSessionProvider.notifier).refreshOnResume();

      expect(repository.fetchProfileCalls, 0);
      expect(current().status, AuthStatus.unauthenticated);
    });

    test('a pending password change stays pending', () async {
      repository.restoreResult = Result.success(
        AuthSession.signedIn(testUser(), mustChangePassword: true),
      );
      await session();
      repository.profileResult = Result.success(head());

      await container.read(authSessionProvider.notifier).refreshOnResume();

      expect(current().status, AuthStatus.mustChangePassword);
    });

    test('a failure leaves the session as it was', () async {
      repository.restoreResult = Result.success(AuthSession.signedIn(head()));
      await session();
      repository.profileResult = const Result.failure(
        Failure.network(message: 'offline'),
      );

      await container.read(authSessionProvider.notifier).refreshOnResume();

      expect(current().user?.isDepartmentHead, isTrue);
    });

    test('an answer that lands after sign-out does not sign back in', () async {
      repository.restoreResult = Result.success(AuthSession.signedIn(testUser()));
      await session();
      final slow = Completer<void>();
      repository
        ..holdProfile = slow
        ..profileResult = Result.success(head());
      final notifier = container.read(authSessionProvider.notifier);

      final refresh = notifier.refreshOnResume();
      await notifier.logout();
      slow.complete();
      await refresh;

      expect(current().status, AuthStatus.unauthenticated);
      expect(current().user, isNull);
    });

    test('an answer for another user (signed in again meanwhile) is dropped',
        () async {
      repository.restoreResult = Result.success(AuthSession.signedIn(testUser()));
      await session();
      final slow = Completer<void>();
      repository
        ..holdProfile = slow
        ..profileResult = Result.success(head());
      final notifier = container.read(authSessionProvider.notifier);

      final refresh = notifier.refreshOnResume();
      repository.loginResult = Result.success(
        AuthSession.signedIn(testUser(id: 'someone-else')),
      );
      await notifier.login(
        email: 'somphone.vilaysone@nexton.la',
        password: 'password1',
      );
      slow.complete();
      await refresh;

      expect(current().user?.id, 'someone-else');
      expect(current().user?.isDepartmentHead, isFalse);
    });
  });

  group('teardown', () {
    test('logout clears the session locally', () async {
      repository.restoreResult = Result.success(
        AuthSession.signedIn(testUser()),
      );
      await session();

      await container.read(authSessionProvider.notifier).logout();

      expect(repository.logoutCalls, 1);
      expect(current().status, AuthStatus.unauthenticated);
    });

    test(
      'an unrecoverable 401 from the interceptor signs the user out',
      () async {
        repository.restoreResult = Result.success(
          AuthSession.signedIn(testUser()),
        );
        await session();
        expect(current().status, AuthStatus.authenticated);

        repository.sessionExpired.add(SessionEndReason.expired);
        // Let the stream listener and its async logout settle.
        await Future<void>.delayed(Duration.zero);

        expect(repository.logoutCalls, 1);
        expect(current().status, AuthStatus.unauthenticated);
      },
    );

    test('a forced sign-out carries its reason until it has been said', () async {
      repository.restoreResult = Result.success(
        AuthSession.signedIn(testUser()),
      );
      await session();

      repository.sessionExpired.add(SessionEndReason.accountDisabled);
      await Future<void>.delayed(Duration.zero);

      expect(current().endReason, SessionEndReason.accountDisabled);

      container.read(authSessionProvider.notifier).clearEndReason();

      expect(current().status, AuthStatus.unauthenticated);
      expect(current().endReason, isNull);
    });

    test('a repeat of the same loss keeps the first reason', () async {
      repository.restoreResult = Result.success(
        AuthSession.signedIn(testUser()),
      );
      await session();

      // Requests in flight together each report it; a straggler may even
      // report a different reason.
      repository.sessionExpired
        ..add(SessionEndReason.accountDisabled)
        ..add(SessionEndReason.accountDisabled)
        ..add(SessionEndReason.expired);
      await Future<void>.delayed(Duration.zero);

      expect(current().endReason, SessionEndReason.accountDisabled);
      expect(repository.logoutCalls, 1);
    });

    test('a late report after the reason was said is not said again', () async {
      repository.restoreResult = Result.success(
        AuthSession.signedIn(testUser()),
      );
      await session();

      repository.sessionExpired.add(SessionEndReason.accountDisabled);
      await Future<void>.delayed(Duration.zero);
      container.read(authSessionProvider.notifier).clearEndReason();

      repository.sessionExpired.add(SessionEndReason.expired);
      await Future<void>.delayed(Duration.zero);

      expect(current().endReason, isNull);
    });

    test('a sign-out the user chose has no reason', () async {
      repository.restoreResult = Result.success(
        AuthSession.signedIn(testUser()),
      );
      await session();

      await container.read(authSessionProvider.notifier).logout();

      expect(current().endReason, isNull);
    });

    test('a forced sign-out also drops a pending password change', () async {
      repository.restoreResult = Result.success(
        AuthSession.signedIn(testUser(), mustChangePassword: true),
      );
      await session();

      repository.sessionExpired.add(SessionEndReason.expired);
      await Future<void>.delayed(Duration.zero);

      expect(current().status, AuthStatus.unauthenticated);
    });
  });
}
