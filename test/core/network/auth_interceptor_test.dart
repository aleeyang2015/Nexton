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
import 'package:next_on/features/notifications/data/datasources/device_remote_data_source.dart';
import 'package:next_on/features/notifications/data/datasources/push_api_paths.dart';

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

  /// When set, the refresh's answer waits for it: a slow server (#56).
  Completer<void>? holdRefresh;

  /// The next answer on a path waits for the completer set here (#89): a
  /// request that left the phone and is answered much later.
  final Map<String, Completer<void>> holdPath = {};

  /// When set, the answer to a request sent again after a refresh waits for
  /// it (#89).
  Completer<void>? holdReplay;

  void queue(String path, List<_Reply> answers) => replies[path] = answers;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (slow) await Future<void>.delayed(const Duration(milliseconds: 10));
    if (options.path == ApiPaths.refresh) await holdRefresh?.future;
    await holdPath.remove(options.path)?.future;
    if (options.extra['auth_retried'] == true) await holdReplay?.future;

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

    test('a request marked no-refresh gets its 401 as it is: no refresh, no '
        'session ended, the tokens untouched (#52)', () async {
      final h = await _Harness.create();
      const path = '/mobile/devices/dev-1';
      h.adapter.queue(path, [_unauthorized]);
      h.adapter.queue(ApiPaths.refresh, [_rotatedTokens]);
      final before = await h.tokens.readAccessToken();

      await expectLater(
        h.client.delete<dynamic>(
          path,
          options: Options(extra: {AuthInterceptor.noRefreshFlag: true}),
        ),
        throwsA(isA<DioException>()),
      );

      expect(h.requestsTo(ApiPaths.refresh), isEmpty);
      expect(h.sessionExpiredEvents, isEmpty);
      expect(await h.tokens.readAccessToken(), before);
    });

    test('the logout (#56): its 401 as it is, no refresh, no session ended, '
        'the tokens untouched, and no bearer sent', () async {
      final h = await _Harness.create();
      h.adapter.queue(ApiPaths.logout, [_unauthorized]);
      h.adapter.queue(ApiPaths.refresh, [_rotatedTokens]);

      await expectLater(
        h.client.post<dynamic>(
          ApiPaths.logout,
          data: {'refresh_token': 'refresh-1'},
        ),
        throwsA(isA<DioException>()),
      );

      expect(h.requestsTo(ApiPaths.refresh), isEmpty);
      expect(h.sessionExpiredEvents, isEmpty);
      expect(await h.tokens.readAccessToken(), 'access-1');
      expect(await h.tokens.readRefreshToken(), 'refresh-1');
      expect(
        h
            .requestsTo(ApiPaths.logout)
            .single
            .headers[AppConstants.authorizationHeader],
        isNull,
      );
    });

    test('HR ended the sign-in (#56): SESSION_EXPIRED, then the refresh '
        'answers INVALID_TOKEN: signed out once, "session expired"', () async {
      final h = await _Harness.create();
      const ended = _Reply(401, {
        'success': false,
        'error': {
          'code': 'SESSION_EXPIRED',
          'message': 'Your session was ended by an administrator',
        },
      });
      h.adapter.queue(ApiPaths.me, [ended, ended]);
      h.adapter.queue(ApiPaths.refresh, [_unauthorized]);

      await Future.wait([
        expectLater(
          h.client.get<dynamic>(ApiPaths.me),
          throwsA(isA<DioException>()),
        ),
        expectLater(
          h.client.get<dynamic>(ApiPaths.me),
          throwsA(isA<DioException>()),
        ),
      ]);

      expect(h.requestsTo(ApiPaths.refresh), hasLength(1));
      expect(h.sessionExpiredEvents, [SessionEndReason.expired]);
      expect(await h.tokens.readRefreshToken(), isNull);
    });

    test('a refresh that answers after a sign-out cleared the tokens writes '
        'nothing back (#56)', () async {
      final h = await _Harness.create();
      h.adapter.queue(ApiPaths.me, [_unauthorized, _okProfile]);
      h.adapter.queue(ApiPaths.refresh, [_rotatedTokens]);
      h.adapter.holdRefresh = Completer<void>();

      final call = h.client.get<dynamic>(ApiPaths.me);
      await pumpEventQueue();
      // The sign-out clears the phone's copy while the refresh runs.
      await h.tokens.clear();
      h.adapter.holdRefresh!.complete();
      await expectLater(call, throwsA(isA<DioException>()));

      expect(await h.tokens.readAccessToken(), isNull);
      expect(await h.tokens.readRefreshToken(), isNull);
      expect(h.sessionExpiredEvents, isEmpty);
    });

    test('the last user\'s refresh, refused after someone else signed in, '
        'leaves the new sign-in alone (#56)', () async {
      final h = await _Harness.create();
      h.adapter.queue(ApiPaths.me, [_unauthorized]);
      h.adapter.queue(ApiPaths.refresh, [_unauthorized]);
      h.adapter.holdRefresh = Completer<void>();

      final call = h.client.get<dynamic>(ApiPaths.me);
      await pumpEventQueue();
      // A signs out; B signs in.
      await h.tokens.clear();
      await h.tokens.writeAccessToken('access-b');
      await h.tokens.writeRefreshToken('refresh-b');
      h.adapter.holdRefresh!.complete();
      await expectLater(call, throwsA(isA<DioException>()));

      expect(await h.tokens.readAccessToken(), 'access-b');
      expect(await h.tokens.readRefreshToken(), 'refresh-b');
      expect(h.sessionExpiredEvents, isEmpty);
    });

    group('a 401 for a request of another sign-in (#89)', () {
      const leave = '/core_hr/leave/requests';

      /// The caller's own 401, not some other failure.
      final is401 = isA<DioException>().having(
        (e) => e.response?.statusCode,
        'status',
        401,
      );

      /// Starts a POST that leaves with the tokens stored now and is
      /// answered only when the returned completer completes.
      Future<(Future<dynamic>, Completer<void>)> sendHeld(_Harness h) async {
        final hold = Completer<void>();
        h.adapter.holdPath[leave] = hold;
        final call = h.client.post<dynamic>(leave, data: {'reason': 'A'});
        while (h.requestsTo(leave).isEmpty) {
          await Future<void>.delayed(Duration.zero);
        }
        return (call, hold);
      }

      test('the last user\'s request, refused after someone else signed in, '
          'is not renewed and not sent again under the new sign-in', () async {
        final h = await _Harness.create();
        h.adapter.queue(leave, [_unauthorized, _okProfile]);
        h.adapter.queue(ApiPaths.refresh, [_rotatedTokens]);

        final (call, hold) = await sendHeld(h);
        expect(h.authHeaderOf(0), 'Bearer access-1');
        // A signs out; B signs in.
        await h.tokens.clear();
        await h.tokens.writeAccessToken('access-b');
        await h.tokens.writeRefreshToken('refresh-b');
        hold.complete();

        // The caller gets its 401.
        await expectLater(call, throwsA(is401));
        // A's leave request was sent once, and never with B's token.
        expect(h.requestsTo(leave), hasLength(1));
        expect(h.requestsTo(ApiPaths.refresh), isEmpty);
        // B's sign-in is untouched.
        expect(await h.tokens.readAccessToken(), 'access-b');
        expect(await h.tokens.readRefreshToken(), 'refresh-b');
        expect(h.sessionExpiredEvents, isEmpty);
      });

      test('a refused renewal can no longer sign the next user out for the '
          'last user\'s request', () async {
        final h = await _Harness.create();
        h.adapter.queue(leave, [_unauthorized]);
        h.adapter.queue(ApiPaths.refresh, [_unauthorized]);

        final (call, hold) = await sendHeld(h);
        await h.tokens.clear();
        await h.tokens.writeAccessToken('access-b');
        await h.tokens.writeRefreshToken('refresh-b');
        hold.complete();
        await expectLater(call, throwsA(is401));

        expect(h.requestsTo(ApiPaths.refresh), isEmpty);
        expect(await h.tokens.readAccessToken(), 'access-b');
        expect(await h.tokens.readRefreshToken(), 'refresh-b');
        expect(h.sessionExpiredEvents, isEmpty);
      });

      test('the last user\'s /auth/me, already renewed and sent again, '
          'refused a second time after someone else signed in: the next '
          'user is not signed out', () async {
        final h = await _Harness.create();
        h.adapter.queue(ApiPaths.me, [_unauthorized, _unauthorized]);
        h.adapter.queue(ApiPaths.refresh, [_rotatedTokens]);

        final hold = h.adapter.holdReplay = Completer<void>();

        final call = h.client.get<dynamic>(ApiPaths.me);
        // The first 401, the renewal, and the replay going out with access-2.
        while (h.requestsTo(ApiPaths.me).length < 2) {
          await Future<void>.delayed(Duration.zero);
        }
        expect(
          h.requestsTo(ApiPaths.me).last.headers[AppConstants
              .authorizationHeader],
          'Bearer access-2',
        );
        // A signs out; B signs in.
        await h.tokens.clear();
        await h.tokens.writeAccessToken('access-b');
        await h.tokens.writeRefreshToken('refresh-b');
        hold.complete();

        await expectLater(call, throwsA(is401));
        expect(await h.tokens.readAccessToken(), 'access-b');
        expect(await h.tokens.readRefreshToken(), 'refresh-b');
        expect(h.sessionExpiredEvents, isEmpty);
      });

      test('the same user signed in again (a password change): their own '
          'late request gets its 401 too, and the new sign-in stays', () async {
        final h = await _Harness.create();
        h.adapter.queue(leave, [_unauthorized, _okProfile]);
        h.adapter.queue(ApiPaths.refresh, [_rotatedTokens]);

        final (call, hold) = await sendHeld(h);
        // The re-login writes a new pair; nothing tells the interceptor it
        // is the same person.
        await h.tokens.writeAccessToken('access-again');
        await h.tokens.writeRefreshToken('refresh-again');
        hold.complete();

        await expectLater(call, throwsA(is401));
        expect(h.requestsTo(ApiPaths.refresh), isEmpty);
        expect(await h.tokens.readAccessToken(), 'access-again');
        expect(h.sessionExpiredEvents, isEmpty);
      });

      test('several requests sent with no access token (only a refresh '
          'token is stored) are all renewed, as before', () async {
        final h = await _Harness.create(accessToken: null);
        h.adapter.slow = true;
        h.adapter.queue(ApiPaths.me, [
          _unauthorized,
          _unauthorized,
          _okProfile,
          _okProfile,
        ]);
        h.adapter.queue(ApiPaths.refresh, [_rotatedTokens]);

        await Future.wait([
          h.client.get<dynamic>(ApiPaths.me),
          h.client.get<dynamic>(ApiPaths.me),
        ]);

        expect(h.requestsTo(ApiPaths.me), hasLength(4));
        expect(h.sessionExpiredEvents, isEmpty);
      });

      test('a request sent while nobody was signed in is not sent again '
          'under whoever signed in since', () async {
        final h = await _Harness.create(accessToken: null, refreshToken: null);
        h.adapter.queue(leave, [_unauthorized, _okProfile]);
        h.adapter.queue(ApiPaths.refresh, [_rotatedTokens]);

        final (call, hold) = await sendHeld(h);
        expect(h.authHeaderOf(0), isNull);
        await h.tokens.writeAccessToken('access-b');
        await h.tokens.writeRefreshToken('refresh-b');
        hold.complete();

        await expectLater(call, throwsA(is401));
        expect(h.requestsTo(leave), hasLength(1));
        expect(h.requestsTo(ApiPaths.refresh), isEmpty);
        expect(await h.tokens.readAccessToken(), 'access-b');
      });

      test('the same sign-in, renewed meanwhile by another request: the late '
          '401 is still renewed and sent again (unchanged)', () async {
        final h = await _Harness.create();
        h.adapter.queue(leave, [_unauthorized, _okProfile]);
        h.adapter.queue(ApiPaths.me, [_unauthorized, _okProfile]);
        h.adapter.queue(ApiPaths.refresh, [_rotatedTokens]);

        // Leaves with access-1 and is answered late.
        final (call, hold) = await sendHeld(h);
        // Meanwhile another request of the same sign-in renews the token.
        await h.client.get<dynamic>(ApiPaths.me);
        expect(await h.tokens.readAccessToken(), 'access-2');
        hold.complete();

        await call;
        expect(h.requestsTo(leave), hasLength(2));
        expect(
          h.requestsTo(leave).last.headers[AppConstants.authorizationHeader],
          'Bearer access-2',
        );
        expect(h.sessionExpiredEvents, isEmpty);
      });

      test('renewed twice meanwhile: still the same sign-in', () async {
        final h = await _Harness.create();
        h.adapter.queue(leave, [_unauthorized, _okProfile]);
        h.adapter.queue(ApiPaths.me, [
          _unauthorized,
          _okProfile,
          _unauthorized,
          _okProfile,
        ]);
        h.adapter.queue(ApiPaths.refresh, [
          _rotatedTokens,
          const _Reply(200, {
            'success': true,
            'data': {'access_token': 'access-3', 'expires_at': 1773505562},
          }),
          const _Reply(200, {
            'success': true,
            'data': {'access_token': 'access-4', 'expires_at': 1773505562},
          }),
        ]);

        final (call, hold) = await sendHeld(h);
        await h.client.get<dynamic>(ApiPaths.me);
        await h.client.get<dynamic>(ApiPaths.me);
        expect(await h.tokens.readAccessToken(), 'access-3');
        hold.complete();

        await call;
        expect(h.requestsTo(leave), hasLength(2));
      });

      test('the last user\'s token renewed earlier does not make their late '
          'request the next user\'s', () async {
        final h = await _Harness.create();
        h.adapter.queue(leave, [_unauthorized, _okProfile]);
        h.adapter.queue(ApiPaths.me, [_unauthorized, _okProfile]);
        h.adapter.queue(ApiPaths.refresh, [_rotatedTokens]);

        // A's request leaves with access-1; A's token is then renewed to
        // access-2; then A signs out and B signs in.
        final (call, hold) = await sendHeld(h);
        await h.client.get<dynamic>(ApiPaths.me);
        await h.tokens.clear();
        await h.tokens.writeAccessToken('access-b');
        await h.tokens.writeRefreshToken('refresh-b');
        hold.complete();

        await expectLater(call, throwsA(is401));
        expect(h.requestsTo(leave), hasLength(1));
        expect(h.requestsTo(ApiPaths.refresh), hasLength(1));
        expect(await h.tokens.readAccessToken(), 'access-b');
        expect(h.sessionExpiredEvents, isEmpty);
      });
    });

    test('a refresh that sends no new refresh token (#56: no rotation) keeps '
        'the saved one', () async {
      final h = await _Harness.create();
      h.adapter.queue(ApiPaths.me, [_unauthorized, _okProfile]);
      h.adapter.queue(ApiPaths.refresh, [
        const _Reply(200, {
          'success': true,
          'data': {'access_token': 'access-2', 'expires_at': 1773505562},
        }),
      ]);

      final response = await h.client.get<dynamic>(ApiPaths.me);

      expect(response.statusCode, 200);
      expect(await h.tokens.readAccessToken(), 'access-2');
      expect(await h.tokens.readRefreshToken(), 'refresh-1');
      expect(h.sessionExpiredEvents, isEmpty);
    });

    test('a multipart upload after the token ran out is sent again, from a '
        'fresh copy of its form (#59)', () async {
      final h = await _Harness.create();
      const path = '/core_hr/employees/emp-1/photo';
      h.adapter.queue(path, [_unauthorized, _okProfile]);
      h.adapter.queue(ApiPaths.refresh, [_rotatedTokens]);

      final response = await h.client.put<dynamic>(
        path,
        data: FormData.fromMap({
          'photo': MultipartFile.fromBytes([1, 2, 3], filename: 'me.jpg'),
        }),
      );

      expect(response.statusCode, 200);
      expect(h.requestsTo(path), hasLength(2));
      expect(
        h.requestsTo(path).last.headers[AppConstants.authorizationHeader],
        'Bearer access-2',
      );
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

    test('a refresh the API refused with another code ends the session: '
        'that token will never work', () async {
      for (final reply in const [
        _Reply(400, {
          'success': false,
          'error': {'code': 'INVALID_REQUEST', 'message': 'bad body'},
        }),
        _Reply(404, {
          'success': false,
          'error': {'code': 'TENANT_NOT_FOUND', 'message': 'no such company'},
        }),
        _Reply(403, {
          'success': false,
          'error': {'code': 'TENANT_MISMATCH', 'message': 'other company'},
        }),
      ]) {
        final h = await _Harness.create();
        h.adapter.queue(ApiPaths.me, [_unauthorized]);
        h.adapter.queue(ApiPaths.refresh, [reply]);

        await expectLater(
          h.client.get<dynamic>(ApiPaths.me),
          throwsA(isA<DioException>()),
        );

        expect(
          await h.tokens.readRefreshToken(),
          isNull,
          reason: 'refresh answered ${reply.status}',
        );
        expect(h.sessionExpiredEvents, [SessionEndReason.expired]);
      }
    });

    test('a 4xx that is not the API\'s keeps the session: a proxy answered, '
        'not the server', () async {
      final (failure, h) = await refreshAnswering(const _Reply(403));

      await expectSessionKept(h);
      expect(failure, isA<NetworkFailure>());
    });

    test('a throttled refresh does not make the request that asked look '
        'throttled', () async {
      final (failure, _) = await refreshAnswering(
        const _Reply(429, {
          'success': false,
          'error': {'code': 'RATE_LIMITED', 'message': 'slow down'},
        }),
      );

      // A punch reads a 429 as its own cooldown; this one was the refresh's.
      expect((failure as NetworkFailure).statusCode, isNull);
      expect(failure.errorCode, ApiErrorCodes.noInternet);
    });

    test('a 401 that lands after the session ended reports nothing '
        'more', () async {
      final h = await _Harness.create();
      h.adapter.queue('/core_hr/employees', [_unauthorized]);
      h.adapter.queue(ApiPaths.refresh, [
        const _Reply(403, {
          'success': false,
          'error': {'code': 'USER_INACTIVE', 'message': 'User is inactive'},
        }),
      ]);

      await expectLater(
        h.client.get<dynamic>('/core_hr/employees'),
        throwsA(isA<DioException>()),
      );
      expect(h.sessionExpiredEvents, [SessionEndReason.accountDisabled]);

      // A straggler from the same screen. Nothing is stored any more, so it
      // must not start a refresh or replace the reason with "expired".
      await expectLater(
        h.client.get<dynamic>('/core_hr/employees'),
        throwsA(isA<DioException>()),
      );

      expect(h.sessionExpiredEvents, [SessionEndReason.accountDisabled]);
      expect(h.requestsTo(ApiPaths.refresh).length, 1);
    });

    test('parallel 401s on a refused refresh all report the same reason',
        () async {
      final h = await _Harness.create();
      h.adapter
        ..slow = true
        ..queue('/a', [_unauthorized])
        ..queue('/b', [_unauthorized])
        ..queue(ApiPaths.refresh, [
          const _Reply(403, {
            'success': false,
            'error': {'code': 'USER_INACTIVE', 'message': 'User is inactive'},
          }),
        ]);

      await Future.wait([
        h.client.get<dynamic>('/a').then<void>((_) {}, onError: (_) {}),
        h.client.get<dynamic>('/b').then<void>((_) {}, onError: (_) {}),
      ]);

      expect(h.requestsTo(ApiPaths.refresh).length, 1);
      expect(h.sessionExpiredEvents, isNotEmpty);
      expect(
        h.sessionExpiredEvents.toSet(),
        {SessionEndReason.accountDisabled},
      );
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

    test('NOT_APPROVER or FORBIDDEN (an OT refusal) does not end the session, '
        'and asks for no refresh', () async {
      final h = await _Harness.create();
      h.adapter.queue('/core_hr/attendance/ot-requests/ot-1/cancel', [
        const _Reply(403, {
          'success': false,
          'error': {'code': 'NOT_APPROVER', 'message': 'not your step'},
        }),
        const _Reply(403, {
          'success': false,
          'error': {'code': 'FORBIDDEN', 'message': 'reject it'},
        }),
      ]);

      for (var i = 0; i < 2; i++) {
        await expectLater(
          h.client.put<dynamic>('/core_hr/attendance/ot-requests/ot-1/cancel'),
          throwsA(isA<DioException>()),
        );
      }

      expect(h.sessionExpiredEvents, isEmpty);
      expect(h.requestsTo(ApiPaths.refresh), isEmpty);
      expect(await h.tokens.readAccessToken(), isNotNull);
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

    test('TENANT_INACTIVE on a call that asked for bytes (the payslip PDF) '
        'still ends the session', () async {
      final h = await _Harness.create();
      h.adapter.queue('/payroll/payslips/my/p-1/pdf', [companyOff]);

      Object? thrown;
      try {
        await h.client.get<List<int>>(
          '/payroll/payslips/my/p-1/pdf',
          options: Options(responseType: ResponseType.bytes),
        );
      } on DioException catch (e) {
        thrown = e.error;
      }

      expect(thrown, isA<AuthFailure>());
      expect((thrown as AuthFailure).code, 'TENANT_INACTIVE');
      expect(h.sessionExpiredEvents, [SessionEndReason.companyInactive]);
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

  group('the sign-off DELETE at sign-out (#52, #71)', () {
    final path = PushPaths.device('dev-1');
    const gone = _Reply(204);

    test('an expired access token is renewed and the DELETE sent again: the '
        'row goes off, no session ended', () async {
      final h = await _Harness.create();
      h.adapter.queue(path, [_unauthorized, gone]);
      h.adapter.queue(ApiPaths.refresh, [_rotatedTokens]);

      await DeviceRemoteDataSourceImpl(h.client).unregister('dev-1');

      final deletes = h.requestsTo(path).toList();
      expect(deletes, hasLength(2));
      expect(
        deletes.last.headers[AppConstants.authorizationHeader],
        'Bearer access-2',
      );
      expect(h.requestsTo(ApiPaths.refresh), hasLength(1));
      expect(h.sessionExpiredEvents, isEmpty);
    });

    test('a refused refresh: the DELETE fails, no second DELETE', () async {
      final h = await _Harness.create();
      h.adapter.queue(path, [_unauthorized]);
      h.adapter.queue(ApiPaths.refresh, [_unauthorized]);

      await expectLater(
        DeviceRemoteDataSourceImpl(h.client).unregister('dev-1'),
        throwsA(isA<DioException>()),
      );

      expect(h.requestsTo(path), hasLength(1));
    });

    test('no signal on the refresh: the DELETE fails, the stored tokens '
        'stay as they were', () async {
      final h = await _Harness.create();
      h.adapter.queue(path, [_unauthorized]);
      h.adapter.queue(ApiPaths.refresh, [
        const _Reply.noAnswer(DioExceptionType.connectionError),
      ]);

      await expectLater(
        DeviceRemoteDataSourceImpl(h.client).unregister('dev-1'),
        throwsA(isA<DioException>()),
      );

      expect(h.requestsTo(path), hasLength(1));
      expect(await h.tokens.readAccessToken(), 'access-1');
      expect(await h.tokens.readRefreshToken(), 'refresh-1');
      expect(h.sessionExpiredEvents, isEmpty);
    });
  });
}
