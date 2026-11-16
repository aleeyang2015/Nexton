import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/constants/app_constants.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/network/api_client.dart';
import 'package:next_on/core/network/api_error_mapper.dart';
import 'package:next_on/core/network/api_paths.dart';
import 'package:next_on/core/network/auth_interceptor.dart';
import 'package:next_on/core/network/network_info.dart';
import 'package:next_on/core/network/session_end_reason.dart';
import 'package:next_on/core/network/token_storage.dart';

import '../../support/auth_test_doubles.dart';

/// One scripted answer from the fake server.
class _Reply {
  final int status;
  final Map<String, dynamic> body;

  /// A body sent as it is, in place of [body]: what a Wi-Fi login page looks
  /// like to the App.
  final String? html;

  /// When set, the request never gets an answer: the adapter throws this.
  final DioExceptionType? transportError;

  const _Reply(this.status, [this.body = const {}])
    : html = null,
      transportError = null;

  const _Reply.html(this.html)
    : status = 200,
      body = const {},
      transportError = null;

  const _Reply.noAnswer(DioExceptionType this.transportError)
    : status = 0,
      body = const {},
      html = null;
}

/// Stands in for the network. Answers from a per-path queue and records every
/// request it saw, so a test can assert on headers and call counts.
class _FakeAdapter implements HttpClientAdapter {
  final Map<String, List<_Reply>> replies = {};
  final List<RequestOptions> requests = [];

  /// Delays every answer by a microtask hop so overlapping calls really do
  /// overlap.
  bool slow = false;

  void queue(String path, List<_Reply> answers) => replies[path] = answers;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (slow) await Future<void>.delayed(const Duration(milliseconds: 10));

    final queued = replies[options.path];
    final reply = queued == null || queued.isEmpty
        ? const _Reply(404, {'success': false})
        : (queued.length == 1 ? queued.first : queued.removeAt(0));

    final transportError = reply.transportError;
    if (transportError != null) {
      throw DioException(requestOptions: options, type: transportError);
    }

    final html = reply.html;
    if (html != null) {
      return ResponseBody.fromString(
        html,
        reply.status,
        headers: {
          Headers.contentTypeHeader: ['text/html'],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode(reply.body),
      reply.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _Harness {
  final _FakeAdapter adapter;
  final InMemorySecureStore store;
  final SecureTokenStorage tokens;
  final AuthInterceptor interceptor;
  final ApiClient client;
  final List<SessionEndReason> sessionExpiredEvents = [];

  _Harness._(
    this.adapter,
    this.store,
    this.tokens,
    this.interceptor,
    this.client,
  );

  static Future<_Harness> create({
    String? accessToken = 'access-1',
    String? refreshToken = 'refresh-1',
  }) async {
    final adapter = _FakeAdapter();
    final store = InMemorySecureStore();
    final tokens = SecureTokenStorage(store);

    if (accessToken != null) await tokens.writeAccessToken(accessToken);
    if (refreshToken != null) await tokens.writeRefreshToken(refreshToken);

    final refreshClient = Dio(ApiClient.buildBaseOptions())
      ..httpClientAdapter = adapter;

    final interceptor = AuthInterceptor(
      tokenStorage: tokens,
      refreshClient: refreshClient,
    );

    // Same composition and ordering as dioProvider: auth first, so it sees the
    // raw 401 before NetworkInterceptor maps it to a Failure.
    final dio = Dio()..httpClientAdapter = adapter;
    interceptor.attachTo(dio);
    dio.interceptors.add(NetworkInterceptor());

    final harness = _Harness._(
      adapter,
      store,
      tokens,
      interceptor,
      ApiClient(dio: dio),
    );
    interceptor.onSessionExpired.listen(harness.sessionExpiredEvents.add);
    return harness;
  }

  String? authHeaderOf(int index) =>
      adapter.requests[index].headers[AppConstants.authorizationHeader]
          as String?;

  Iterable<RequestOptions> requestsTo(String path) =>
      adapter.requests.where((r) => r.path == path);
}

const _okProfile = _Reply(200, {
  'success': true,
  'data': {'id': 'u1'},
});

const _unauthorized = _Reply(401, {
  'success': false,
  'error': {'code': 'INVALID_TOKEN', 'message': 'token expired'},
});

const _rotatedTokens = _Reply(200, {
  'success': true,
  'data': {
    'access_token': 'access-2',
    'refresh_token': 'refresh-2',
    'expires_at': 1773505562,
  },
});

void main() {
  group('request headers', () {
    test('attaches the access token as a bearer', () async {
      final h = await _Harness.create();
      h.adapter.queue(ApiPaths.me, [_okProfile]);

      await h.client.get<dynamic>(ApiPaths.me);

      expect(h.authHeaderOf(0), 'Bearer access-1');
    });

    test('sends no X-Tenant-Slug header when no slug is defined', () async {
      final h = await _Harness.create();
      h.adapter.queue(ApiPaths.me, [_okProfile]);

      await h.client.get<dynamic>(ApiPaths.me);

      expect(
        h.adapter.requests.first.headers,
        isNot(contains(AppConstants.tenantSlugHeader)),
      );
    });

    test('base options carry X-Tenant-Slug only for a non-empty slug', () {
      expect(
        ApiClient.buildBaseOptions().headers,
        isNot(contains(AppConstants.tenantSlugHeader)),
      );
      expect(
        ApiClient.buildBaseOptions(
          tenantSlug: 'nexton-demo',
        ).headers[AppConstants.tenantSlugHeader],
        'nexton-demo',
      );
    });

    test('omits the bearer with no token stored', () async {
      final h = await _Harness.create(accessToken: null, refreshToken: null);
      h.adapter.queue(ApiPaths.login, [
        const _Reply(200, {
          'success': true,
          'data': {
            'access_token': 'a',
            'refresh_token': 'r',
            'must_change_password': false,
          },
        }),
      ]);

      await h.client.post<dynamic>(ApiPaths.login, data: {});

      expect(h.authHeaderOf(0), isNull);
    });
  });

  group('401 handling', () {
    test('refreshes, rotates both tokens and replays the request', () async {
      final h = await _Harness.create();
      h.adapter.queue(ApiPaths.me, [_unauthorized, _okProfile]);
      h.adapter.queue(ApiPaths.refresh, [_rotatedTokens]);

      final response = await h.client.get<dynamic>(ApiPaths.me);

      expect(response.statusCode, 200);
      expect(await h.tokens.readAccessToken(), 'access-2');
      expect(await h.tokens.readRefreshToken(), 'refresh-2');
      expect(h.requestsTo(ApiPaths.me).length, 2);
      // The replay carries the refreshed token.
      expect(
        h
            .requestsTo(ApiPaths.me)
            .last
            .headers[AppConstants.authorizationHeader],
        'Bearer access-2',
      );
      expect(h.sessionExpiredEvents, isEmpty);
    });

    test('stores the rotated expiry alongside the rotated tokens', () async {
      final h = await _Harness.create();
      await h.tokens.writeAccessTokenExpiry(
        DateTime.fromMillisecondsSinceEpoch(1773504662 * 1000, isUtc: true),
      );
      h.adapter.queue(ApiPaths.me, [_unauthorized, _okProfile]);
      h.adapter.queue(ApiPaths.refresh, [_rotatedTokens]);

      await h.client.get<dynamic>(ApiPaths.me);

      // The refresh response's own expires_at replaces the one it superseded.
      expect(
        await h.tokens.readAccessTokenExpiry(),
        DateTime.fromMillisecondsSinceEpoch(1773505562 * 1000, isUtc: true),
      );
    });

    test('a refresh that reports no expiry drops the stale one', () async {
      final h = await _Harness.create();
      await h.tokens.writeAccessTokenExpiry(
        DateTime.fromMillisecondsSinceEpoch(1773504662 * 1000, isUtc: true),
      );
      h.adapter.queue(ApiPaths.me, [_unauthorized, _okProfile]);
      h.adapter.queue(ApiPaths.refresh, [
        const _Reply(200, {
          'success': true,
          'data': {'access_token': 'access-2', 'refresh_token': 'refresh-2'},
        }),
      ]);

      await h.client.get<dynamic>(ApiPaths.me);

      // The old expiry described the token that was just replaced.
      expect(await h.tokens.readAccessTokenExpiry(), isNull);
      expect(await h.tokens.readAccessToken(), 'access-2');
    });

    test('sends no bearer on the refresh call itself', () async {
      final h = await _Harness.create();
      h.adapter.queue(ApiPaths.me, [_unauthorized, _okProfile]);
      h.adapter.queue(ApiPaths.refresh, [_rotatedTokens]);

      await h.client.get<dynamic>(ApiPaths.me);

      final refreshRequest = h.requestsTo(ApiPaths.refresh).single;
      expect(refreshRequest.headers[AppConstants.authorizationHeader], isNull);
      expect((refreshRequest.data as Map)['refresh_token'], 'refresh-1');
    });

    test('parallel 401s share a single refresh', () async {
      final h = await _Harness.create();
      h.adapter.slow = true;
      h.adapter.queue(ApiPaths.me, [
        _unauthorized,
        _unauthorized,
        _unauthorized,
        _okProfile,
        _okProfile,
        _okProfile,
      ]);
      h.adapter.queue(ApiPaths.refresh, [_rotatedTokens]);

      await Future.wait([
        h.client.get<dynamic>(ApiPaths.me),
        h.client.get<dynamic>(ApiPaths.me),
        h.client.get<dynamic>(ApiPaths.me),
      ]);

      expect(h.requestsTo(ApiPaths.refresh).length, 1);
      expect(h.sessionExpiredEvents, isEmpty);
    });

    test('a failed refresh clears the session and signals expiry', () async {
      final h = await _Harness.create();
      h.adapter.queue(ApiPaths.me, [_unauthorized]);
      h.adapter.queue(ApiPaths.refresh, [_unauthorized]);

      await expectLater(
        h.client.get<dynamic>(ApiPaths.me),
        throwsA(isA<DioException>()),
      );

      expect(await h.tokens.readAccessToken(), isNull);
      expect(await h.tokens.readRefreshToken(), isNull);
      expect(await h.tokens.readAccessTokenExpiry(), isNull);
      expect(h.sessionExpiredEvents, [SessionEndReason.expired]);
    });

    test('a disabled account clears the session and says so', () async {
      final h = await _Harness.create();
      h.adapter.queue(ApiPaths.me, [_unauthorized]);
      h.adapter.queue(ApiPaths.refresh, [
        const _Reply(403, {
          'success': false,
          'error': {'code': 'USER_INACTIVE', 'message': 'User is inactive'},
        }),
      ]);

      await expectLater(
        h.client.get<dynamic>(ApiPaths.me),
        throwsA(isA<DioException>()),
      );

      expect(await h.tokens.readAccessToken(), isNull);
      expect(await h.tokens.readRefreshToken(), isNull);
      expect(h.sessionExpiredEvents, [SessionEndReason.accountDisabled]);
    });

    test('a switched-off company on refresh clears the session and says '
        'so', () async {
      final h = await _Harness.create();
      h.adapter.queue(ApiPaths.me, [_unauthorized]);
      h.adapter.queue(ApiPaths.refresh, [
        const _Reply(403, {
          'success': false,
          'error': {'code': 'TENANT_INACTIVE', 'message': 'Tenant is off'},
        }),
      ]);

      await expectLater(
        h.client.get<dynamic>(ApiPaths.me),
        throwsA(isA<DioException>()),
      );

      expect(await h.tokens.readAccessToken(), isNull);
      expect(h.sessionExpiredEvents, [SessionEndReason.companyInactive]);
    });

    /// Runs one request whose refresh comes back as [refresh], and returns
    /// the failure the caller is handed.
    Future<(Object?, _Harness)> refreshAnswering(_Reply refresh) async {
      final h = await _Harness.create();
      h.adapter.queue(ApiPaths.me, [_unauthorized]);
      h.adapter.queue(ApiPaths.refresh, [refresh]);

      Object? failure;
      try {
        await h.client.get<dynamic>(ApiPaths.me);
      } on DioException catch (e) {
        failure = e.error;
      }
      return (failure, h);
    }

    Future<void> expectSessionKept(_Harness h) async {
      expect(await h.tokens.readAccessToken(), 'access-1');
      expect(await h.tokens.readRefreshToken(), 'refresh-1');
      expect(h.sessionExpiredEvents, isEmpty);
      // One attempt, no replay of the request that asked.
      expect(h.requestsTo(ApiPaths.refresh).length, 1);
      expect(h.requestsTo(ApiPaths.me).length, 1);
    }

    test('a refresh that times out keeps the session; the caller sees a '
        'network failure, not a 401', () async {
      final (failure, h) = await refreshAnswering(
        const _Reply.noAnswer(DioExceptionType.receiveTimeout),
      );

      await expectSessionKept(h);
      expect(failure, isA<NetworkFailure>());
      expect((failure as NetworkFailure).errorCode, ApiErrorCodes.timeout);
    });

    test('a refresh with no connection keeps the session', () async {
      final (failure, h) = await refreshAnswering(
        const _Reply.noAnswer(DioExceptionType.connectionError),
      );

      await expectSessionKept(h);
      expect((failure as NetworkFailure).errorCode, ApiErrorCodes.noInternet);
    });

    test('a refresh answered 503 keeps the session; the caller sees a server '
        'failure', () async {
      final (failure, h) = await refreshAnswering(
        const _Reply(503, {
          'success': false,
          'error': {'code': 'TENANT_UNAVAILABLE', 'message': 'restarting'},
        }),
      );

      await expectSessionKept(h);
      expect(failure, isA<ServerFailure>());
    });

    test('a refresh answered 429 keeps the session', () async {
      final (failure, h) = await refreshAnswering(
        const _Reply(429, {
          'success': false,
          'error': {'code': 'RATE_LIMITED', 'message': 'slow down'},
        }),
      );

      await expectSessionKept(h);
      expect(failure, isA<NetworkFailure>());
    });

    test('a refresh answered with a Wi-Fi login page keeps the session',
        () async {
      final (failure, h) = await refreshAnswering(
        const _Reply.html('<html><body>Sign in to Wi-Fi</body></html>'),
      );

      await expectSessionKept(h);
      expect(failure, isA<NetworkFailure>());
    });

    test('a refresh answered 200 with no tokens keeps the session', () async {
      final (failure, h) = await refreshAnswering(
        const _Reply(200, {'success': true, 'data': <String, dynamic>{}}),
      );

      await expectSessionKept(h);
      expect(failure, isA<NetworkFailure>());
    });

    test('a wrong password on login makes no refresh call and ends '
        'nothing', () async {
      // A stale token is still stored, so the login goes out with a bearer.
      final h = await _Harness.create();
      h.adapter.queue(ApiPaths.login, [
        const _Reply(401, {
          'success': false,
          'error': {
            'code': 'INVALID_CREDENTIALS',
            'message': 'Invalid email or password',
          },
        }),
      ]);

      Object? failure;
      try {
        await h.client.post<dynamic>(ApiPaths.login, data: const {});
      } on DioException catch (e) {
        failure = e.error;
      }

      expect((failure as AuthFailure).code, 'INVALID_CREDENTIALS');
      expect(h.requestsTo(ApiPaths.refresh), isEmpty);
      expect(h.sessionExpiredEvents, isEmpty);
      expect(await h.tokens.readAccessToken(), 'access-1');
    });

    test('no refresh token means no refresh call at all', () async {
      final h = await _Harness.create(refreshToken: null);
      h.adapter.queue(ApiPaths.me, [_unauthorized]);

      await expectLater(
        h.client.get<dynamic>(ApiPaths.me),
        throwsA(isA<DioException>()),
      );

      expect(h.requestsTo(ApiPaths.refresh), isEmpty);
      expect(h.sessionExpiredEvents, hasLength(1));
    });

    test('a second 401 on /auth/me ends the session', () async {
      final h = await _Harness.create();
      h.adapter.queue(ApiPaths.me, [_unauthorized, _unauthorized]);
      h.adapter.queue(ApiPaths.refresh, [_rotatedTokens]);

      await expectLater(
        h.client.get<dynamic>(ApiPaths.me),
        throwsA(isA<DioException>()),
      );

      expect(h.requestsTo(ApiPaths.me).length, 2);
      expect(h.sessionExpiredEvents, hasLength(1));
      expect(await h.tokens.readAccessToken(), isNull);
    });

    test('a second 401 elsewhere propagates and keeps the session', () async {
      final h = await _Harness.create();
      h.adapter.queue('/core_hr/employees', [_unauthorized, _unauthorized]);
      h.adapter.queue(ApiPaths.refresh, [_rotatedTokens]);

      await expectLater(
        h.client.get<dynamic>('/core_hr/employees'),
        throwsA(isA<DioException>()),
      );

      expect(h.sessionExpiredEvents, isEmpty);
      expect(await h.tokens.readAccessToken(), 'access-2');
    });

    test('a non-401 error is passed straight through, mapped', () async {
      final h = await _Harness.create();
      h.adapter.queue(ApiPaths.me, [
        const _Reply(500, {
          'success': false,
          'error': {'code': 'INTERNAL_ERROR', 'message': 'boom'},
        }),
      ]);

      await expectLater(
        h.client.get<dynamic>(ApiPaths.me),
        throwsA(isA<DioException>()),
      );

      expect(h.requestsTo(ApiPaths.refresh), isEmpty);
      expect(h.sessionExpiredEvents, isEmpty);
    });
  });

  group('403 handling', () {
    const companyOff = _Reply(403, {
      'success': false,
      'error': {'code': 'TENANT_INACTIVE', 'message': 'Tenant is not active'},
    });

    test('TENANT_INACTIVE on a signed-in call ends the session, with no '
        'refresh', () async {
      final h = await _Harness.create();
      h.adapter.queue('/core_hr/employees', [companyOff]);

      Object? thrown;
      try {
        await h.client.get<dynamic>('/core_hr/employees');
      } on DioException catch (e) {
        thrown = e.error;
      }

      // The caller still gets the failure, with the code the Lao text hangs on.
      expect(thrown, isA<AuthFailure>());
      expect((thrown as AuthFailure).code, 'TENANT_INACTIVE');
      expect(h.requestsTo(ApiPaths.refresh), isEmpty);
      expect(await h.tokens.readAccessToken(), isNull);
      expect(await h.tokens.readRefreshToken(), isNull);
      expect(h.sessionExpiredEvents, hasLength(1));
    });

    test('a late TENANT_INACTIVE for the previous user spares the new '
        'session', () async {
      final h = await _Harness.create();
      h.adapter
        ..slow = true
        ..queue('/core_hr/employees', [companyOff]);

      // The request leaves with access-1; before its answer lands, that user
      // signs out and another signs in on the same phone.
      final pending = h.client.get<dynamic>('/core_hr/employees');
      while (h.adapter.requests.isEmpty) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(h.authHeaderOf(0), 'Bearer access-1');
      await h.tokens.writeAccessToken('access-other-user');

      await expectLater(pending, throwsA(isA<DioException>()));

      expect(await h.tokens.readAccessToken(), 'access-other-user');
      expect(h.sessionExpiredEvents, isEmpty);
    });

    test('TENANT_INACTIVE on a login that still carries a stale token ends '
        'that stale session', () async {
      final h = await _Harness.create();
      h.adapter.queue(ApiPaths.login, [companyOff]);

      await expectLater(
        h.client.post<dynamic>(ApiPaths.login, data: const {}),
        throwsA(isA<DioException>()),
      );

      expect(await h.tokens.readAccessToken(), isNull);
    });

    test('TENANT_INACTIVE on a login has no session to end', () async {
      final h = await _Harness.create(accessToken: null, refreshToken: null);
      h.adapter.queue(ApiPaths.login, [companyOff]);

      await expectLater(
        h.client.post<dynamic>(ApiPaths.login, data: const {}),
        throwsA(isA<DioException>()),
      );

      expect(h.sessionExpiredEvents, isEmpty);
    });

    test('any other 403 leaves the session alone', () async {
      final h = await _Harness.create();
      h.adapter.queue('/core_hr/employees', [
        const _Reply(403, {
          'success': false,
          'error': {'code': 'MODULE_NOT_ACTIVE', 'message': 'not bought'},
        }),
      ]);

      Object? thrown;
      try {
        await h.client.get<dynamic>('/core_hr/employees');
      } on DioException catch (e) {
        thrown = e.error;
      }

      expect(thrown, isA<ValidationFailure>());
      expect((thrown as ValidationFailure).code, 'MODULE_NOT_ACTIVE');
      expect(await h.tokens.readAccessToken(), 'access-1');
      expect(h.sessionExpiredEvents, isEmpty);
    });
  });
}
