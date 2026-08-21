import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/constants/app_constants.dart';
import 'package:next_on/core/errors/failure.dart';
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
  late StreamController<void> sessionExpired;
  late AuthRepositoryImpl repository;

  setUp(() {
    remote = FakeAuthRemoteDataSource();
    store = InMemorySecureStore();
    local = AuthLocalDataSourceImpl(
      store: store,
      tokenStorage: SecureTokenStorage(store),
    );
    sessionExpired = StreamController<void>.broadcast();
    repository = AuthRepositoryImpl(
      remote: remote,
      local: local,
      sessionExpired: sessionExpired.stream,
    );
  });

  tearDown(() => sessionExpired.close());

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
