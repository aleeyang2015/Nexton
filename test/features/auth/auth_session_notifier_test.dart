import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/auth/auth_providers.dart';
import 'package:next_on/features/auth/domain/entities/auth_session.dart';
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

    test('releases the session and reloads the profile', () async {
      await session();
      repository.profileResult = Result.success(testUser(id: 'refreshed'));

      final result = await container
          .read(authSessionProvider.notifier)
          .changePassword(
            currentPassword: 'current-pass',
            newPassword: 'new-password',
            confirmPassword: 'new-password',
          );

      expect(result.isSuccess, isTrue);
      expect(repository.fetchProfileCalls, 1);
      expect(current().status, AuthStatus.authenticated);
      expect(current().mustChangePassword, isFalse);
      expect(current().user!.id, 'refreshed');
    });

    test('a failed profile reload still releases the session', () async {
      await session();
      repository.profileResult = const Result.failure(
        Failure.network(message: 'No internet connection'),
      );

      await container
          .read(authSessionProvider.notifier)
          .changePassword(
            currentPassword: 'current-pass',
            newPassword: 'new-password',
            confirmPassword: 'new-password',
          );

      expect(current().status, AuthStatus.authenticated);
      // Falls back to the profile already in hand.
      expect(current().user!.id, 'cce14a0e');
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
      expect(repository.fetchProfileCalls, 0);
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

        repository.sessionExpired.add(null);
        // Let the stream listener and its async logout settle.
        await Future<void>.delayed(Duration.zero);

        expect(repository.logoutCalls, 1);
        expect(current().status, AuthStatus.unauthenticated);
      },
    );

    test('a forced sign-out also drops a pending password change', () async {
      repository.restoreResult = Result.success(
        AuthSession.signedIn(testUser(), mustChangePassword: true),
      );
      await session();

      repository.sessionExpired.add(null);
      await Future<void>.delayed(Duration.zero);

      expect(current().status, AuthStatus.unauthenticated);
    });
  });
}
