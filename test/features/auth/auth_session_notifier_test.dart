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

    group('a session-end report while the password is being changed (#91)',
        () {
      /// Every status the session went through, in order.
      List<AuthStatus> watchStatuses() {
        final seen = <AuthStatus>[];
        container.listen(authSessionProvider, (_, next) {
          final status = next.valueOrNull?.status;
          if (status != null) seen.add(status);
        });
        return seen;
      }

      Future<Result<Unit>> change() => container
          .read(authSessionProvider.notifier)
          .changePassword(
            currentPassword: 'current-pass',
            newPassword: 'new-password',
            confirmPassword: 'new-password',
          );

      /// The network layer reports the session lost, and the report is
      /// delivered.
      Future<void> report(SessionEndReason reason) async {
        repository.sessionExpired.add(reason);
        await pumpEventQueue();
      }

      test('the old refresh token refused while the App signs in again: the '
          'user is never signed out', () async {
        await session();
        final seen = watchStatuses();
        repository
          ..loginResult = Result.success(AuthSession.signedIn(testUser()))
          // What is stored after the sign-in: the new session.
          ..restoreResult = Result.success(AuthSession.signedIn(testUser()))
          ..whileLoggingIn = () => report(SessionEndReason.expired);

        final result = await change();
        await pumpEventQueue();

        expect(result.isSuccess, isTrue);
        expect(seen, isNot(contains(AuthStatus.unauthenticated)));
        expect(current().status, AuthStatus.authenticated);
        expect(current().mustChangePassword, isFalse);
        expect(current().endReason, isNull);
        expect(repository.logoutCalls, 0);
      });

      test('the report\'s clearing of the tokens landed on the new pair: '
          'nothing is stored after the sign-in, so the session ends as '
          '"password changed", not as a signed-in App with no tokens',
          () async {
        await session();
        repository
          ..loginResult = Result.success(AuthSession.signedIn(testUser()))
          ..restoreResult = const Result.success(
            AuthSession.unauthenticated(),
          )
          ..whileLoggingIn = () => report(SessionEndReason.expired);

        await change();
        await pumpEventQueue();

        expect(current().status, AuthStatus.unauthenticated);
        expect(current().endReason, SessionEndReason.passwordChanged);
      });

      test('no report came: the session is the sign-in\'s own, and nothing '
          'is read back', () async {
        await session();
        final restores = repository.restoreCalls;
        repository.loginResult = Result.success(
          AuthSession.signedIn(testUser(id: 'refreshed')),
        );

        await change();

        expect(current().user!.id, 'refreshed');
        expect(repository.restoreCalls, restores);
      });

      test('refused while the change itself is still on its way, and the '
          'change and the sign-in then succeed: never signed out', () async {
        await session();
        final seen = watchStatuses();
        repository
          ..loginResult = Result.success(AuthSession.signedIn(testUser()))
          ..restoreResult = Result.success(AuthSession.signedIn(testUser()))
          ..whileChangingPassword = () => report(SessionEndReason.expired);

        await change();
        await pumpEventQueue();

        expect(seen, isNot(contains(AuthStatus.unauthenticated)));
        expect(current().status, AuthStatus.authenticated);
        expect(repository.logoutCalls, 0);
      });

      test('the sign-in then fails: the session ends once, as "password '
          'changed"', () async {
        await session();
        final seen = watchStatuses();
        repository
          ..loginResult = const Result.failure(
            Failure.network(message: 'No internet connection'),
          )
          ..whileLoggingIn = () => report(SessionEndReason.expired);

        await change();
        await pumpEventQueue();

        expect(current().status, AuthStatus.unauthenticated);
        expect(current().endReason, SessionEndReason.passwordChanged);
        expect(
          seen.where((s) => s == AuthStatus.unauthenticated),
          hasLength(1),
        );
      });

      test('the sign-in fails and the report said why (account disabled): '
          'that reason is the one shown', () async {
        await session();
        repository
          ..loginResult = const Result.failure(
            Failure.network(message: 'No internet connection'),
          )
          ..whileLoggingIn = () => report(SessionEndReason.accountDisabled);

        await change();
        await pumpEventQueue();

        expect(current().status, AuthStatus.unauthenticated);
        expect(current().endReason, SessionEndReason.accountDisabled);
      });

      test('the change itself is refused: a report held meanwhile is acted '
          'on, the session did end', () async {
        await session();
        repository
          ..changePasswordResult = const Result.failure(
            Failure.network(message: 'No internet connection'),
          )
          ..whileChangingPassword = () => report(SessionEndReason.expired);

        final result = await change();
        await pumpEventQueue();

        expect(result.isFailure, isTrue);
        expect(current().status, AuthStatus.unauthenticated);
        expect(current().endReason, SessionEndReason.expired);
      });

      test('once the change is over, a report signs out as before', () async {
        await session();
        repository.loginResult = Result.success(
          AuthSession.signedIn(testUser()),
        );
        await change();

        await report(SessionEndReason.expired);

        expect(current().status, AuthStatus.unauthenticated);
        expect(current().endReason, SessionEndReason.expired);
      });
    });

    group('the user signs out while the password is being changed (#93)',
        () {
      Future<Result<Unit>> changeIn(ProviderContainer c) => c
          .read(authSessionProvider.notifier)
          .changePassword(
            currentPassword: 'current-pass',
            newPassword: 'new-password',
            confirmPassword: 'new-password',
          );

      Future<Result<Unit>> change() => changeIn(container);

      test('"Sign out" finished while the App signs in again: the user stays '
          'signed out, and the sign-in that came back is ended too', () async {
        await session();
        repository
          ..loginResult = Result.success(AuthSession.signedIn(testUser()))
          // The whole sign-out runs before the sign-in answers.
          ..whileLoggingIn = () =>
              container.read(authSessionProvider.notifier).logout();

        final result = await change();
        await pumpEventQueue();

        // The password did change.
        expect(result.isSuccess, isTrue);
        expect(current().status, AuthStatus.unauthenticated);
        expect(current().endReason, isNull);
        // The user's own sign-out, then the new sign-in's pair: both ended
        // on the server, and nothing left stored.
        expect(repository.logoutCalls, 2);
        expect(repository.logoutEndSession, [true, true]);
      });

      test('"Sign out" still on its way (signing the phone off for push) '
          'when the sign-in answers: the App is never shown as signed in, '
          'and the sign-out ends the new sign-in itself', () async {
        final signOff = Completer<void>();
        final c = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(repository),
            beforeSignOutProvider.overrideWithValue(
              ({required bool tokensLive}) => signOff.future,
            ),
          ],
        );
        addTearDown(c.dispose);
        await c.read(authSessionProvider.future);
        final seen = <AuthStatus>[];
        c.listen(authSessionProvider, (_, next) {
          final status = next.valueOrNull?.status;
          if (status != null) seen.add(status);
        });
        late Future<void> signingOut;
        repository
          ..loginResult = Result.success(AuthSession.signedIn(testUser()))
          ..whileLoggingIn = () async {
            signingOut = c.read(authSessionProvider.notifier).logout();
            await pumpEventQueue();
          };

        await changeIn(c);
        // The sign-in has answered; the sign-out is still signing off.
        expect(seen, isNot(contains(AuthStatus.authenticated)));
        expect(repository.logoutCalls, 0);

        signOff.complete();
        await signingOut;

        expect(seen, isNot(contains(AuthStatus.authenticated)));
        expect(
          c.read(authSessionProvider).requireValue.status,
          AuthStatus.unauthenticated,
        );
        // Once: by the sign-out, for the pair stored by then.
        expect(repository.logoutEndSession, [true]);
      });

      test('"Sign out" while the session is read back after a held report: '
          'stays signed out', () async {
        await session();
        repository
          ..loginResult = Result.success(AuthSession.signedIn(testUser()))
          ..restoreResult = Result.success(AuthSession.signedIn(testUser()))
          ..whileLoggingIn = () async {
            repository.sessionExpired.add(SessionEndReason.expired);
            await pumpEventQueue();
          }
          ..whileRestoring = () =>
              container.read(authSessionProvider.notifier).logout();

        await change();
        await pumpEventQueue();

        expect(current().status, AuthStatus.unauthenticated);
        expect(current().endReason, isNull);
      });

      test('the sign-in fails after the user left: still signed out, with '
          'no "password changed" message for a sign-out they asked for',
          () async {
        await session();
        repository
          ..loginResult = const Result.failure(
            Failure.network(message: 'No internet connection'),
          )
          ..whileLoggingIn = () =>
              container.read(authSessionProvider.notifier).logout();

        await change();
        await pumpEventQueue();

        expect(current().status, AuthStatus.unauthenticated);
        expect(current().endReason, isNull);
        // Only the user's own sign-out: there is no new sign-in to end.
        expect(repository.logoutCalls, 1);
      });

      test('nobody left: the new session is published, and no sign-in is '
          'ended', () async {
        await session();
        repository.loginResult = Result.success(
          AuthSession.signedIn(testUser(id: 'refreshed')),
        );

        await change();

        expect(current().status, AuthStatus.authenticated);
        expect(current().user!.id, 'refreshed');
        expect(repository.logoutCalls, 0);
      });
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

  group('signing this phone off for push (#52)', () {
    /// A container whose sign-off hook records when it ran, against the
    /// repository's logout (which clears the tokens).
    ProviderContainer withHook(
      Future<void> Function({required bool tokensLive}) hook,
    ) {
      final c = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          beforeSignOutProvider.overrideWithValue(hook),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('sign-out signs the phone off before the tokens are cleared',
        () async {
      repository.restoreResult = Result.success(
        AuthSession.signedIn(testUser()),
      );
      final order = <String>[];
      final c = withHook(({required bool tokensLive}) async {
        order.add(
          'hook(tokensLive: $tokensLive) at logout '
          '#${repository.logoutCalls}',
        );
      });
      await c.read(authSessionProvider.future);

      await c.read(authSessionProvider.notifier).logout();

      expect(order, ['hook(tokensLive: true) at logout #0']);
      expect(repository.logoutCalls, 1);
      expect(
        c.read(authSessionProvider).requireValue.status,
        AuthStatus.unauthenticated,
      );
    });

    test('a sign-off that fails never stops the sign-out', () async {
      repository.restoreResult = Result.success(
        AuthSession.signedIn(testUser()),
      );
      final c = withHook(({required bool tokensLive}) async {
        throw Exception('no signal');
      });
      await c.read(authSessionProvider.future);

      await c.read(authSessionProvider.notifier).logout();

      expect(repository.logoutCalls, 1);
      expect(
        c.read(authSessionProvider).requireValue.status,
        AuthStatus.unauthenticated,
      );
    });

    test('a second tap while a sign-out is on its way: one sign-out',
        () async {
      repository.restoreResult = Result.success(
        AuthSession.signedIn(testUser()),
      );
      final hold = Completer<void>();
      var hooks = 0;
      final c = withHook(({required bool tokensLive}) async {
        hooks++;
        await hold.future;
      });
      await c.read(authSessionProvider.future);
      final notifier = c.read(authSessionProvider.notifier);

      final first = notifier.logout();
      final second = notifier.logout();
      hold.complete();
      await Future.wait([first, second]);

      expect(hooks, 1);
      expect(repository.logoutCalls, 1);
    });

    test('a failed re-login after a password change: the access token still '
        'works, so the phone is signed off in full, before the tokens go',
        () async {
      repository.restoreResult = Result.success(
        AuthSession.signedIn(testUser()),
      );
      final order = <String>[];
      final c = withHook(({required bool tokensLive}) async {
        order.add('hook($tokensLive) at logout #${repository.logoutCalls}');
      });
      await c.read(authSessionProvider.future);
      repository.loginResult = const Result.failure(
        Failure.network(message: 'No internet connection'),
      );

      await c.read(authSessionProvider.notifier).changePassword(
        currentPassword: 'current-pass',
        newPassword: 'new-password',
        confirmPassword: 'new-password',
      );
      await pumpEventQueue();

      expect(order, ['hook(true) at logout #0']);
    });

    test('a session the network gave up on mid-restore: the FCM token '
        'still goes', () async {
      final seen = <bool>[];
      final c = withHook(({required bool tokensLive}) async {
        seen.add(tokensLive);
      });
      repository.whileRestoring = () async {
        repository.sessionExpired.add(SessionEndReason.expired);
        await Future<void>.delayed(Duration.zero);
      };

      await c.read(authSessionProvider.future);
      await pumpEventQueue();

      expect(seen, [false]);
    });

    test('a forced sign-out (tokens already gone): the hook with '
        'tokensLive false, after the session is down', () async {
      repository.restoreResult = Result.success(
        AuthSession.signedIn(testUser()),
      );
      final seen = <bool>[];
      final c = withHook(({required bool tokensLive}) async {
        seen.add(tokensLive);
      });
      await c.read(authSessionProvider.future);

      repository.sessionExpired.add(SessionEndReason.expired);
      await pumpEventQueue();

      expect(seen, [false]);
      expect(
        c.read(authSessionProvider).requireValue.endReason,
        SessionEndReason.expired,
      );
    });
  });

  group('ending the sign-in on the server (#56)', () {
    ProviderContainer withHook(
      Future<void> Function({required bool tokensLive}) hook,
    ) {
      final c = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          beforeSignOutProvider.overrideWithValue(hook),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('sign-out: the device row, then the server logout, then the clear',
        () async {
      repository.restoreResult = Result.success(
        AuthSession.signedIn(testUser()),
      );
      final order = <String>[];
      repository.onLogout = ({required bool endSession}) =>
          order.add('logout(endSession: $endSession)');
      final c = withHook(({required bool tokensLive}) async {
        order.add('device');
      });
      await c.read(authSessionProvider.future);

      await c.read(authSessionProvider.notifier).logout();

      expect(order, ['device', 'logout(endSession: true)']);
      expect(
        c.read(authSessionProvider).requireValue.status,
        AuthStatus.unauthenticated,
      );
    });

    test('a forced sign-out while the sign-off waits, then someone else signs '
        'in: the waiting sign-out ends nothing of theirs', () async {
      repository.restoreResult = Result.success(
        AuthSession.signedIn(testUser()),
      );
      final hold = Completer<void>();
      var hooks = 0;
      final c = withHook(({required bool tokensLive}) async {
        hooks++;
        if (hooks == 1) await hold.future;
      });
      await c.read(authSessionProvider.future);

      final signingOut = c.read(authSessionProvider.notifier).logout();
      await pumpEventQueue();
      // A request refused meanwhile signs A out; B signs in.
      repository.sessionExpired.add(SessionEndReason.expired);
      await pumpEventQueue();
      repository.loginResult = Result.success(
        AuthSession.signedIn(testUser(id: 'user-b')),
      );
      await c
          .read(authSessionProvider.notifier)
          .login(email: 'b@nexton.la', password: 'secret-b');
      hold.complete();
      await signingOut;

      // Only the forced sign-out's local clear: no server logout, and B
      // stays signed in.
      expect(repository.logoutEndSession, [false]);
      expect(c.read(authSessionProvider).requireValue.user?.id, 'user-b');
    });

    test('a forced sign-out (tokens gone): no server logout', () async {
      repository.restoreResult = Result.success(
        AuthSession.signedIn(testUser()),
      );
      final c = withHook(({required bool tokensLive}) async {});
      await c.read(authSessionProvider.future);

      repository.sessionExpired.add(SessionEndReason.expired);
      await pumpEventQueue();

      expect(repository.logoutEndSession, [false]);
    });

    test('a failed re-login after a password change: the tokens still work, '
        'so the server ends that sign-in too', () async {
      repository.restoreResult = Result.success(
        AuthSession.signedIn(testUser()),
      );
      final c = withHook(({required bool tokensLive}) async {});
      await c.read(authSessionProvider.future);
      repository.loginResult = const Result.failure(
        Failure.network(message: 'No internet connection'),
      );

      await c.read(authSessionProvider.notifier).changePassword(
        currentPassword: 'current-pass',
        newPassword: 'new-password',
        confirmPassword: 'new-password',
      );

      expect(repository.logoutEndSession, [true]);
    });

    test('a session the network gave up on mid-restore: no server logout',
        () async {
      final c = withHook(({required bool tokensLive}) async {});
      repository.whileRestoring = () async {
        repository.sessionExpired.add(SessionEndReason.expired);
        await Future<void>.delayed(Duration.zero);
      };

      await c.read(authSessionProvider.future);
      await pumpEventQueue();

      expect(repository.logoutEndSession, [false]);
    });
  });
}
