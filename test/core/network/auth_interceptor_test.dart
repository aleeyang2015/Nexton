import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/constants/app_constants.dart';
import 'package:next_on/core/network/api_client.dart';
import 'package:next_on/core/network/api_paths.dart';
import 'package:next_on/core/network/auth_interceptor.dart';
import 'package:next_on/core/network/network_info.dart';
import 'package:next_on/core/network/token_storage.dart';

import '../../support/auth_test_doubles.dart';

/// One scripted answer from the fake server.
class _Reply {
  final int status;
  final Map<String, dynamic> body;

  const _Reply(this.status, [this.body = const {}]);
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
  final List<void> sessionExpiredEvents = [];

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

    test('sends the dev tenant slug header', () async {
      final h = await _Harness.create();
      h.adapter.queue(ApiPaths.me, [_okProfile]);

      await h.client.get<dynamic>(ApiPaths.me);

      expect(
        h.adapter.requests.first.headers[AppConstants.tenantSlugHeader],
        AppConstants.tenantSlug,
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
      expect(h.sessionExpiredEvents, hasLength(1));
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
}
