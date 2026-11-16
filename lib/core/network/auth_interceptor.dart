import 'dart:async';

import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import 'api_error_mapper.dart';
import 'api_paths.dart';
import 'api_response.dart';
import 'session_end_reason.dart';
import 'token_storage.dart';

/// What a refresh attempt came back with.
sealed class _RefreshOutcome {
  const _RefreshOutcome();
}

/// The server issued a new pair; [accessToken] is already stored.
class _Refreshed extends _RefreshOutcome {
  final String accessToken;

  const _Refreshed(this.accessToken);
}

/// The server answered, and the answer is no: the tokens are cleared.
class _Dead extends _RefreshOutcome {
  final SessionEndReason reason;

  const _Dead(this.reason);
}

/// No answer about the token at all: a timeout, no connection, a 5xx, a 429,
/// or a body that is not the refresh response (a Wi-Fi login page). The
/// tokens are kept; [error] is what the refresh call failed with, when it
/// failed.
class _Unreachable extends _RefreshOutcome {
  final DioException? error;

  const _Unreachable(this.error);
}

/// Attaches the bearer token and recovers from an expired one.
///
/// Mirrors the contract documented in `features/auth/auth.md`:
///
/// * every request carries `Authorization: Bearer <access_token>` **except**
///   `POST /auth/refresh`, whose credential is the refresh token in its body;
/// * a `401` triggers one refresh-and-retry cycle, guarded by a single-flight
///   mutex so parallel 401s share one in-flight refresh. A `401` on
///   `POST /auth/login` is a wrong password, not an expired token, and passes
///   straight on;
/// * only a refresh the server **refused** ends the session: a `401`, a
///   `403 USER_INACTIVE`, or no refresh token to send. The tokens are cleared
///   and [onSessionExpired] says why;
/// * a refresh that got **no answer about the token** (timeout, no
///   connection, 5xx, 429, a body that is not the refresh response) keeps the
///   session. The request that asked fails with that transport error, so the
///   screen shows "no connection" or "server error" instead of signing out;
/// * a second `401` on `/auth/me` after a successful refresh ends the session.
///   A second `401` on any other path propagates as a normal error and leaves
///   the session alone;
/// * a `403 TENANT_INACTIVE` on a signed-in request (the company was switched
///   off) ends the session with no refresh: the refresh call answers the same
///   403.
class AuthInterceptor extends Interceptor {
  static const String _retriedFlag = 'auth_retried';

  final TokenStorage _tokenStorage;
  final Dio _refreshClient;
  final _sessionExpired = StreamController<SessionEndReason>.broadcast();

  /// The client used to replay a request after a successful refresh. Set by
  /// [attachTo] so the replay goes through the full interceptor chain.
  Dio? _client;

  /// The in-flight refresh, shared by every request that 401s while it runs.
  Future<_RefreshOutcome>? _refreshCall;

  AuthInterceptor({
    required TokenStorage tokenStorage,
    required Dio refreshClient,
  }) : _tokenStorage = tokenStorage,
       _refreshClient = refreshClient;

  /// Emits once per unrecoverable session loss, with the reason. The auth
  /// feature listens and tears the session down; nothing in `core` knows what
  /// that means.
  Stream<SessionEndReason> get onSessionExpired => _sessionExpired.stream;

  /// Registers this interceptor on [dio] and remembers it for retries.
  void attachTo(Dio dio) {
    _client = dio;
    dio.interceptors.add(this);
  }

  void dispose() => _sessionExpired.close();

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_isRefreshCall(options)) {
      return handler.next(options);
    }

    final token = await _tokenStorage.readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers[AppConstants.authorizationHeader] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;

    if (await _isCompanySwitchedOff(err)) {
      await _expireSession(SessionEndReason.companyInactive);
      return handler.next(err);
    }

    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // A wrong email or password. There is no session to refresh, even when a
    // stale token rode along.
    if (_isLoginCall(request)) {
      return handler.next(err);
    }

    // The refresh token itself is dead — no retry loop to attempt.
    if (_isRefreshCall(request)) {
      await _expireSession(SessionEndReason.expired);
      return handler.next(err);
    }

    if (request.extra[_retriedFlag] == true) {
      // A refreshed token still can't read the profile: the session is gone.
      // On any other path, let the caller deal with the 401.
      if (_isSessionProbe(request)) {
        await _expireSession(SessionEndReason.expired);
      }
      return handler.next(err);
    }

    switch (await _refreshTokens()) {
      case _Dead(:final reason):
        await _expireSession(reason);
        return handler.next(err);

      case _Unreachable(:final error):
        // Not an answer about the token, so not a 401 for the caller either:
        // hand over what the refresh failed with, on the original request,
        // and [NetworkInterceptor] maps it to a network or server failure.
        // `restoreSession` keeps the cached session for those.
        return handler.next(
          DioException(
            requestOptions: request,
            type: error?.type ?? DioExceptionType.connectionError,
            error: error?.error,
            response: error?.response,
            message: error?.message,
          ),
        );

      case _Refreshed(:final accessToken):
        try {
          final retried = await _replay(request, accessToken);
          handler.resolve(retried);
        } on DioException catch (e) {
          handler.next(e);
        }
    }
  }

  /// Single-flight refresh: concurrent callers await the same future.
  Future<_RefreshOutcome> _refreshTokens() {
    return _refreshCall ??= _doRefresh().whenComplete(() {
      _refreshCall = null;
    });
  }

  /// Only a refusal from the server clears the tokens. Anything that is not
  /// an answer about the token leaves them where they are: weak signal or a
  /// server restart must never cost the user their session.
  Future<_RefreshOutcome> _doRefresh() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await _tokenStorage.clear();
      return const _Dead(SessionEndReason.expired);
    }

    try {
      final response = await _refreshClient.post<dynamic>(
        ApiPaths.refresh,
        data: {'refresh_token': refreshToken},
      );

      final data = ApiEnvelope.unwrapObject(response.data);
      final access = data['access_token'];
      final rotated = data['refresh_token'];
      if (access is! String || rotated is! String) {
        // A 200 that is not the refresh response, e.g. a Wi-Fi login page.
        return const _Unreachable(null);
      }

      // Both tokens rotate on every refresh, and so does the expiry that
      // describes the access token — writing it unconditionally is what stops
      // the previous token's expiry from outliving it.
      await _tokenStorage.writeAccessToken(access);
      await _tokenStorage.writeRefreshToken(rotated);
      await _tokenStorage.writeAccessTokenExpiry(
        tokenExpiryFromUnixSeconds(data['expires_at']),
      );
      return _Refreshed(access);
    } on DioException catch (error) {
      final reason = _refusalOf(error);
      if (reason == null) return _Unreachable(error);

      await _tokenStorage.clear();
      return _Dead(reason);
    } catch (_) {
      // The body could not be read as the refresh response.
      return const _Unreachable(null);
    }
  }

  /// Why the server refused a refresh, or null when [error] is not a refusal
  /// of the token: no answer at all, a 5xx, a 429.
  static SessionEndReason? _refusalOf(DioException error) {
    final status = error.response?.statusCode;
    if (status == 401) return SessionEndReason.expired;
    if (status != 403) return null;

    switch (ApiError.tryParse(error.response?.data)?.code) {
      case ApiErrorCodes.userInactive:
        return SessionEndReason.accountDisabled;
      case ApiErrorCodes.tenantInactive:
        return SessionEndReason.companyInactive;
      default:
        return null;
    }
  }

  Future<Response<dynamic>> _replay(RequestOptions request, String token) {
    final client = _client;
    if (client == null) {
      throw StateError('AuthInterceptor.attachTo was never called');
    }

    request.extra[_retriedFlag] = true;
    request.headers[AppConstants.authorizationHeader] = 'Bearer $token';
    return client.fetch<dynamic>(request);
  }

  Future<void> _expireSession(SessionEndReason reason) async {
    await _tokenStorage.clear();
    if (!_sessionExpired.isClosed) _sessionExpired.add(reason);
  }

  bool _isLoginCall(RequestOptions options) =>
      options.path.endsWith(ApiPaths.login);

  /// A request of the *current* session refused because the company is
  /// switched off.
  ///
  /// The token the request went out with must still be the stored one. A login
  /// can get the same answer, but it has no session to end and the login screen
  /// shows the message itself; and a slow answer to the previous user's request
  /// must not sign out whoever signed in since.
  Future<bool> _isCompanySwitchedOff(DioException err) async {
    if (err.response?.statusCode != 403) return false;

    final code = ApiError.tryParse(err.response?.data)?.code;
    if (code != ApiErrorCodes.tenantInactive) return false;

    final sent = err.requestOptions.headers[AppConstants.authorizationHeader];
    final current = await _tokenStorage.readAccessToken();
    return current != null && current.isNotEmpty && sent == 'Bearer $current';
  }

  bool _isRefreshCall(RequestOptions options) =>
      options.path.endsWith(ApiPaths.refresh);

  bool _isSessionProbe(RequestOptions options) =>
      options.path.endsWith(ApiPaths.me);
}
