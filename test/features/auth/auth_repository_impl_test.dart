import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/constants/app_constants.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/network/session_end_reason.dart';
import 'package:next_on/core/network/api_error_mapper.dart';
import 'package:next_on/core/network/token_storage.dart';
import 'package:next_on/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:next_on/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:next_on/features/auth/domain/entities/auth_session.dart';

import '../../support/auth_test_doubles.dart';

DioException _httpError(int status, String code, String message) {
  final options = RequestOptions(path: '/auth/me');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(
      requestOptions: options,
      statusCode: status,
      data: {
        'success': false,
        'error': {'code': code, 'message': message},
      },
    ),
  );
}

/// The shape NetworkInterceptor hands the repository: a DioException whose
/// `error` is an already-mapped Failure.
DioException _mappedError(int status, String code, String message) {
  final raw = _httpError(status, code, message);
  return DioException(
    requestOptions: raw.requestOptions,
    response: raw.response,
    type: raw.type,
    error: ApiErrorMapper.fromDioException(raw),
  );
}

void main() {
  late FakeAuthRemoteDataSource remote;
  late InMemorySecureStore store;
  late AuthLocalDataSource local;
  late StreamController<SessionEndReason> sessionExpired;
  late AuthRepositoryImpl repository;

  setUp(() {
    remote = FakeAuthRemoteDataSource();
    store = InMemorySecureStore();
    local = AuthLocalDataSourceImpl(
      store: store,
      tokenStorage: SecureTokenStorage(store),
    );
    sessionExpired = StreamController<SessionEndReason>.broadcast();
    repository = AuthRepositoryImpl(
      remote: remote,
      local: local,
      sessionExpired: sessionExpired.stream,
    );
  });

  tearDown(() => sessionExpired.close());

  group('a re-login the user has already left (#93)', () {
    setUp(() {
      remote
        ..loginResponse = testTokens()
        ..profile = testUserModel();
    });

    test('nothing is stored, and the new sign-in is ended on the server with '
        'its own refresh token', () async {
      final result = await repository.login(
        email: 'somphone.vilaysone@nexton.la',
        password: 'new-password1',
        abandonIf: () => true,
      );

      expect(result.isFailure, isTrue);
      expect(store.values, isEmpty);
      expect(remote.logouts, ['refresh-1']);
      expect(remote.lastLogoutTimeout, AuthRepositoryImpl.logoutTimeout);
      expect(remote.profileCalls, 0);
    });

    test('ending it fails (no signal): still nothing stored, still left',
        () async {
      remote.logoutError = Exception('no signal');

      final result = await repository.login(
        email: 'somphone.vilaysone@nexton.la',
        password: 'new-password1',
        abandonIf: () => true,
      );

      expect(result.isFailure, isTrue);
      expect(store.values, isEmpty);
    });

    test('left after the pair was stored (the tap landed after the first '
        'check): ended with its own refresh token, the pair removed, the '
        'profile not cached', () async {
      var asked = 0;
      final result = await repository.login(
        email: 'somphone.vilaysone@nexton.la',
        password: 'new-password1',
        abandonIf: () => ++asked > 1,
      );

      expect(asked, 2);
      expect(result.isFailure, isTrue);
      expect(remote.logouts, ['refresh-1']);
      expect(store.values, isEmpty);
    });

    test('left after the pair was stored, and another sign-in has replaced '
        'it since: theirs is left alone', () async {
      var asked = 0;
      final result = await repository.login(
        email: 'somphone.vilaysone@nexton.la',
        password: 'new-password1',
        abandonIf: () {
          if (++asked == 1) return false;
          // Someone else's pair, stored meanwhile.
          store.values[AppConstants.refreshTokenKey] = 'refresh-b';
          return true;
        },
      );

      expect(result.isFailure, isTrue);
      expect(remote.logouts, ['refresh-1']);
      expect(store.values[AppConstants.refreshTokenKey], 'refresh-b');
    });

    test('left after the pair was stored, and another sign-in is saved while '
        'the removal checks the stored token: theirs is left alone', () async {
      final gate = Completer<void>();
      var asked = 0;
      final login = repository.login(
        email: 'somphone.vilaysone@nexton.la',
        password: 'new-password1',
        abandonIf: () {
          if (++asked == 1) return false;
          // The removal's read of the stored refresh token waits here.
          store.holdRead[AppConstants.refreshTokenKey] = gate;
          return true;
        },
      );
      // The removal has started reading the stored refresh token.
      for (var i = 0; i < 100; i++) {
        if (asked == 2 &&
            !store.holdRead.containsKey(AppConstants.refreshTokenKey)) {
          break;
        }
        await Future<void>.delayed(Duration.zero);
      }

      // Someone signs in while that read is on its way.
      final other = local.writeTokens(
        accessToken: 'access-b',
        refreshToken: 'refresh-b',
      );
      gate.complete();
      await other;
      final result = await login;

      expect(result.isFailure, isTrue);
      expect(remote.logouts, ['refresh-1']);
      expect(store.values[AppConstants.refreshTokenKey], 'refresh-b');
      expect(store.values[AppConstants.accessTokenKey], 'access-b');
    });

    group('the profile fails after the pair was stored (#120)', () {
      /// Runs the re-login with `/auth/me` held, calls [meanwhile] while it
      /// waits, then lets it fail with [error].
      Future<Failure> failWhileHeld(
        Object error, {
        required bool Function() left,
        Future<void> Function()? meanwhile,
      }) async {
        final gate = Completer<void>();
        remote
          ..holdProfile = gate
          ..profileError = error;
        final login = repository.login(
          email: 'somphone.vilaysone@nexton.la',
          password: 'new-password1',
          abandonIf: left,
        );
        for (var i = 0; i < 100 && remote.profileCalls == 0; i++) {
          await Future<void>.delayed(Duration.zero);
        }
        expect(remote.profileCalls, 1);
        await meanwhile?.call();
        gate.complete();
        return (await login).failureOrNull!;
      }

      final errors = <String, Object Function()>{
        'a failure': () =>
            const Failure.network(message: 'no signal', statusCode: 0),
        'a raw error': () => _mappedError(500, 'INTERNAL_ERROR', 'boom'),
      };

      errors.forEach((kind, error) {
        test('$kind, the user left and another sign-in was saved meanwhile: '
            'theirs is left alone, the left pair is ended', () async {
          var left = false;
          final failure = await failWhileHeld(
            error(),
            left: () => left,
            meanwhile: () async {
              left = true;
              await local.writeTokens(
                accessToken: 'access-b',
                refreshToken: 'refresh-b',
              );
            },
          );

          expect(failure.message, AuthRepositoryImpl.abandonedMessage);
          expect(remote.logouts, ['refresh-1']);
          expect(store.values[AppConstants.refreshTokenKey], 'refresh-b');
          expect(store.values[AppConstants.accessTokenKey], 'access-b');
        });

        test('$kind, the user left and nothing was saved since: the left '
            'pair is removed and ended', () async {
          var left = false;
          final failure = await failWhileHeld(
            error(),
            left: () => left,
            meanwhile: () async => left = true,
          );

          expect(failure.message, AuthRepositoryImpl.abandonedMessage);
          expect(remote.logouts, ['refresh-1']);
          expect(store.values, isEmpty);
        });

        test('$kind, the user has not left: everything is cleared, and the '
            'new sign-in is ended on the server (#122)', () async {
          final failure = await failWhileHeld(error(), left: () => false);

          expect(failure.message, isNot(AuthRepositoryImpl.abandonedMessage));
          expect(remote.logouts, ['refresh-1']);
          expect(remote.lastLogoutTimeout, AuthRepositoryImpl.logoutTimeout);
          expect(store.values, isEmpty);
        });
      });

      test('a renewal replaced the pair, then the user left: the sign-in is '
          'ended on the server by its first refresh token', () async {
        var left = false;
        await failWhileHeld(
          _mappedError(500, 'INTERNAL_ERROR', 'boom'),
          left: () => left,
          meanwhile: () async {
            // A 401 on `/auth/me` renewed the pair (same sign-in, new
            // refresh token), then "Sign out" was tapped.
            store.values[AppConstants.refreshTokenKey] = 'refresh-1b';
            left = true;
          },
        );

        // The server ends a sign-in by its family, so `refresh-1b` is dead
        // too. The phone's copy is not this check's to remove (it cannot
        // tell it from someone else's): the sign-out on its way clears it.
        expect(remote.logouts, ['refresh-1']);
        expect(store.values[AppConstants.refreshTokenKey], 'refresh-1b');
      });
    });

    test('not left: stored as any sign-in, nothing ended', () async {
      final result = await repository.login(
        email: 'somphone.vilaysone@nexton.la',
        password: 'new-password1',
        abandonIf: () => false,
      );

      expect(result.isSuccess, isTrue);
      expect(store.values[AppConstants.refreshTokenKey], 'refresh-1');
      expect(remote.logouts, isEmpty);
    });
  });

  group('login', () {
    test(
      'signs in and caches the session when no change is required',
      () async {
        remote
          ..loginResponse = testTokens()
          ..profile = testUserModel();

        final result = await repository.login(
          email: 'somphone.vilaysone@nexton.la',
          password: 'password1',
        );

        final session = result.dataOrNull!;
        expect(session.status, AuthStatus.authenticated);
        expect(session.mustChangePassword, isFalse);
        expect(session.user!.displayName, 'Somphone Vilaysone');

        expect(store.values[AppConstants.accessTokenKey], 'access-1');
        expect(store.values[AppConstants.refreshTokenKey], 'refresh-1');
        expect(store.values[AppConstants.cachedUserKey], isNotNull);
        // Nothing pending, so nothing is written.
        expect(
          store.values.containsKey(AppConstants.mustChangePasswordKey),
          isFalse,
        );
      },
    );

    test('persists the access-token expiry the login reported', () async {
      final expiry = DateTime.fromMillisecondsSinceEpoch(
        1773504662 * 1000,
        isUtc: true,
      );
      remote
        ..loginResponse = testTokens(expiresAt: expiry)
        ..profile = testUserModel();

      await repository.login(email: 'a@b.la', password: 'password1');

      expect(store.values[AppConstants.expiresAtKey], '1773504662');
    });

    test('a login that reports no expiry stores none', () async {
      remote
        ..loginResponse = testTokens()
        ..profile = testUserModel();

      await repository.login(email: 'a@b.la', password: 'password1');

      expect(store.values.containsKey(AppConstants.expiresAtKey), isFalse);
    });

    test('a rolled-back login leaves no expiry behind', () async {
      remote
        ..loginResponse = testTokens(
          expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
        )
        ..profileError = _mappedError(500, 'INTERNAL_ERROR', 'boom');

      final result = await repository.login(
        email: 'a@b.la',
        password: 'password1',
      );

      expect(result.isFailure, isTrue);
      // The whole session write is rolled back, expiry included.
      expect(store.values, isEmpty);
    });

    test('a rolled-back login is ended on the server by its own refresh '
        'token, and keeps its own failure (#122)', () async {
      remote
        ..loginResponse = testTokens()
        ..profileError = _mappedError(500, 'INTERNAL_ERROR', 'boom');

      final result = await repository.login(
        email: 'a@b.la',
        password: 'password1',
      );

      expect(result.failureOrNull!.message, 'boom');
      expect(remote.logouts, ['refresh-1']);
      expect(store.values, isEmpty);
    });

    test('a rolled-back login whose server logout fails is still rolled '
        'back, with its own failure (#122)', () async {
      remote
        ..loginResponse = testTokens()
        ..profileError = _mappedError(500, 'INTERNAL_ERROR', 'boom')
        ..logoutError = Exception('no signal');

      final result = await repository.login(
        email: 'a@b.la',
        password: 'password1',
      );

      expect(result.failureOrNull!.message, 'boom');
      expect(store.values, isEmpty);
    });

    test(
      'must_change_password: true lands in the pending state and persists',
      () async {
        remote
          ..loginResponse = testTokens(mustChangePassword: true)
          ..profile = testUserModel();

        final session = (await repository.login(
          email: 'a@b.la',
          password: 'password1',
        )).dataOrNull!;

        expect(session.status, AuthStatus.mustChangePassword);
        expect(session.hasSession, isTrue);
        expect(session.isAuthenticated, isFalse);
        expect(store.values[AppConstants.mustChangePasswordKey], 'true');
      },
    );

    test('invalid credentials fail without writing a token', () async {
      remote.loginError = _mappedError(
        401,
        'INVALID_CREDENTIALS',
        'Invalid email or password',
      );

      final result = await repository.login(
        email: 'a@b.la',
        password: 'wrong-password',
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<AuthFailure>());
      expect(result.failureOrNull!.message, 'Invalid email or password');
      expect(store.values, isEmpty);
      expect(remote.profileCalls, 0);
    });

    test(
      'the 429 throttle is a network failure, not a credential one',
      () async {
        remote.loginError = _mappedError(
          429,
          'TOO_MANY_LOGIN_ATTEMPTS',
          'Too many attempts',
        );

        final failure = (await repository.login(
          email: 'a@b.la',
          password: 'password1',
        )).failureOrNull!;

        expect(failure, isA<NetworkFailure>());
      },
    );

    test(
      'rolls the tokens back when /auth/me fails after the token write',
      () async {
        remote
          ..loginResponse = testTokens(mustChangePassword: true)
          ..profileError = _mappedError(500, 'INTERNAL_ERROR', 'boom');

        final result = await repository.login(
          email: 'a@b.la',
          password: 'password1',
        );

        expect(result.isFailure, isTrue);
        // No half-finished session may survive to the next cold start.
        expect(store.values, isEmpty);
        expect(await local.hasTokens(), isFalse);
      },
    );
  });

  group('restoreSession', () {
    test('reports unauthenticated with nothing stored', () async {
      final session = (await repository.restoreSession()).dataOrNull!;

      expect(session.status, AuthStatus.unauthenticated);
      expect(remote.profileCalls, 0);
    });

    test('revalidates a stored session against /auth/me', () async {
      await local.writeTokens(accessToken: 'a', refreshToken: 'r');
      remote.profile = testUserModel();

      final session = (await repository.restoreSession()).dataOrNull!;

      expect(session.status, AuthStatus.authenticated);
      expect(session.user!.email, 'somphone.vilaysone@nexton.la');
      // No cached profile to paint, so the probe is time-boxed.
      expect(remote.lastProfileTimeout, AuthRepositoryImpl.bootstrapTimeout);
    });

    test('a pending password change survives a restart', () async {
      await local.writeTokens(accessToken: 'a', refreshToken: 'r');
      await local.writeMustChangePassword(true);
      remote.profile = testUserModel();

      final session = (await repository.restoreSession()).dataOrNull!;

      expect(session.status, AuthStatus.mustChangePassword);
    });

    test('a pending change survives an offline restart too', () async {
      await local.writeTokens(accessToken: 'a', refreshToken: 'r');
      await local.writeUser(testUserModel());
      await local.writeMustChangePassword(true);
      remote.profileError = DioException(
        requestOptions: RequestOptions(path: '/auth/me'),
        type: DioExceptionType.connectionError,
      );

      final session = (await repository.restoreSession()).dataOrNull!;

      expect(session.status, AuthStatus.mustChangePassword);
      expect(session.user, isNotNull);
    });

    test('being offline does not evict a cached session', () async {
      await local.writeTokens(accessToken: 'a', refreshToken: 'r');
      await local.writeUser(testUserModel());
      remote.profileError = DioException(
        requestOptions: RequestOptions(path: '/auth/me'),
        type: DioExceptionType.connectionError,
      );

      final session = (await repository.restoreSession()).dataOrNull!;

      expect(session.status, AuthStatus.authenticated);
      expect(await local.hasTokens(), isTrue);
      // A cached profile is already on screen, so the probe is not time-boxed.
      expect(remote.lastProfileTimeout, isNull);
    });

    test('a 401 clears the session for good', () async {
      await local.writeTokens(accessToken: 'a', refreshToken: 'r');
      await local.writeUser(testUserModel());
      await local.writeMustChangePassword(true);
      remote.profileError = _mappedError(401, 'INVALID_TOKEN', 'expired');

      final session = (await repository.restoreSession()).dataOrNull!;

      expect(session.status, AuthStatus.unauthenticated);
      expect(store.values, isEmpty);
    });

    for (final code in const [
      'USER_INACTIVE',
      'TENANT_INACTIVE',
      'FORBIDDEN',
      'TENANT_MISMATCH',
    ]) {
      test('a 403 $code on the profile signs out, cache or not', () async {
        await local.writeTokens(accessToken: 'a', refreshToken: 'r');
        await local.writeUser(testUserModel());
        remote.profileError = _mappedError(403, code, 'refused');

        final session = (await repository.restoreSession()).dataOrNull!;

        expect(session.status, AuthStatus.unauthenticated);
        // No token is left to ride along with the next login.
        expect(store.values, isEmpty);
      });
    }

    test('a 5xx keeps the cached identity: the server will be back', () async {
      await local.writeTokens(accessToken: 'a', refreshToken: 'r');
      await local.writeUser(testUserModel());
      remote.profileError = _mappedError(503, 'TENANT_UNAVAILABLE', 'down');

      final session = (await repository.restoreSession()).dataOrNull!;

      expect(session.hasSession, isTrue);
      expect(await local.hasTokens(), isTrue);
    });

    test('an offline start with no cache surfaces the failure', () async {
      await local.writeTokens(accessToken: 'a', refreshToken: 'r');
      remote.profileError = DioException(
        requestOptions: RequestOptions(path: '/auth/me'),
        type: DioExceptionType.connectionError,
      );

      final result = await repository.restoreSession();

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NetworkFailure>());
      // The tokens are still there — this is a transport problem.
      expect(await local.hasTokens(), isTrue);
    });
  });

  group('changePassword', () {
    test('clears the pending flag on success', () async {
      await local.writeTokens(accessToken: 'a', refreshToken: 'r');
      await local.writeMustChangePassword(true);

      final result = await repository.changePassword(
        currentPassword: 'current-pass',
        newPassword: 'new-password',
      );

      expect(result.isSuccess, isTrue);
      expect(await local.readMustChangePassword(), isFalse);
      expect(remote.lastCurrentPassword, 'current-pass');
      expect(remote.lastNewPassword, 'new-password');
    });

    test(
      'a wrong current password is a 400 PASSWORD_MISMATCH auth failure',
      () async {
        await local.writeMustChangePassword(true);
        remote.changePasswordError = _mappedError(
          400,
          'PASSWORD_MISMATCH',
          'Current password is wrong',
        );

        final result = await repository.changePassword(
          currentPassword: 'nope',
          newPassword: 'new-password',
        );

        expect(result.failureOrNull, isA<AuthFailure>());
        expect(result.failureOrNull!.message, 'Current password is wrong');
        // The requirement stands until it is actually satisfied.
        expect(await local.readMustChangePassword(), isTrue);
      },
    );
  });

  group('logout', () {
    test('clears tokens, the cached profile and the pending flag', () async {
      await local.writeTokens(accessToken: 'a', refreshToken: 'r');
      await local.writeUser(testUserModel());
      await local.writeMustChangePassword(true);

      final result = await repository.logout();

      expect(result.isSuccess, isTrue);
      expect(store.values, isEmpty);
    });

    test('a sign-out ends the sign-in on the server with the saved refresh '
        'token, then clears (#56)', () async {
      await local.writeTokens(accessToken: 'a', refreshToken: 'r-1');
      remote.onLogout = () => expect(store.values, isNotEmpty);

      final result = await repository.logout(endSession: true);

      expect(result.isSuccess, isTrue);
      expect(remote.logouts, ['r-1']);
      expect(remote.lastLogoutTimeout, AuthRepositoryImpl.logoutTimeout);
      expect(store.values, isEmpty);
    });

    test('a logout that fails (500, no signal) still clears, quietly', () async {
      await local.writeTokens(accessToken: 'a', refreshToken: 'r-1');
      remote.logoutError = Exception('500');

      final result = await repository.logout(endSession: true);

      expect(result.isSuccess, isTrue);
      expect(store.values, isEmpty);
    });

    test('a server that never answers: cleared after the limit', () {
      fakeAsync((async) {
        local.writeTokens(accessToken: 'a', refreshToken: 'r-1');
        async.flushMicrotasks();
        remote.holdLogout = Completer<void>();

        var done = false;
        repository.logout(endSession: true).then((_) => done = true);
        async.elapse(
          AuthRepositoryImpl.logoutTimeout - const Duration(milliseconds: 1),
        );
        expect(done, isFalse);
        async.elapse(const Duration(milliseconds: 2));
        expect(done, isTrue);
        expect(store.values, isEmpty);
      });
    });

    test('no refresh token saved: no call, still cleared', () async {
      await local.writeUser(testUserModel());

      await repository.logout(endSession: true);

      expect(remote.logouts, isEmpty);
      expect(store.values, isEmpty);
    });

    test('a forced sign-out (endSession false): no server call', () async {
      await local.writeTokens(accessToken: 'a', refreshToken: 'r-1');

      await repository.logout();

      expect(remote.logouts, isEmpty);
      expect(store.values, isEmpty);
    });
  });

  group('currentUser', () {
    test('reads back the cached profile', () async {
      await local.writeUser(testUserModel());

      final user = (await repository.currentUser()).dataOrNull;

      expect(user!.id, 'cce14a0e');
    });

    test('is null with nothing cached', () async {
      expect((await repository.currentUser()).dataOrNull, isNull);
    });
  });
}
