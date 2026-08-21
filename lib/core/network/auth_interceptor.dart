import 'dart:async';

import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import 'api_paths.dart';
import 'api_response.dart';
import 'token_storage.dart';

/// Attaches the bearer token and recovers from an expired one.
///
/// Mirrors the contract documented in `features/auth/auth.md`:
///
/// * every request carries `Authorization: Bearer <access_token>` **except**
///   `POST /auth/refresh`, whose credential is the refresh token in its body;
/// * a `401` triggers one refresh-and-retry cycle, guarded by a single-flight
///   mutex so parallel 401s share one in-flight refresh;
/// * a failed refresh, a `401` from `/auth/refresh` itself, or a second `401`
///   on `/auth/me` clears the tokens and emits on [onSessionExpired]. A second
///   `401` on any other path propagates as a normal error and leaves the
///   session alone.
class AuthInterceptor extends Interceptor {
  static const String _retriedFlag = 'auth_retried';

  final TokenStorage _tokenStorage;
  final Dio _refreshClient;
  final _sessionExpired = StreamController<void>.broadcast();

  /// The client used to replay a request after a successful refresh. Set by
  /// [attachTo] so the replay goes through the full interceptor chain.
  Dio? _client;

  /// The in-flight refresh, shared by every request that 401s while it runs.
  Future<String?>? _refreshCall;

  AuthInterceptor({
    required TokenStorage tokenStorage,
    required Dio refreshClient,
  }) : _tokenStorage = tokenStorage,
       _refreshClient = refreshClient;

  /// Emits once per unrecoverable session loss. The auth feature listens and
  /// tears the session down; nothing in `core` knows what that means.
  Stream<void> get onSessionExpired => _sessionExpired.stream;

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

    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // The refresh token itself is dead — no retry loop to attempt.
    if (_isRefreshCall(request)) {
      await _expireSession();
      return handler.next(err);
    }

    if (request.extra[_retriedFlag] == true) {
      // A refreshed token still can't read the profile: the session is gone.
      // On any other path, let the caller deal with the 401.
      if (_isSessionProbe(request)) {
        await _expireSession();
      }
      return handler.next(err);
    }

    final token = await _refreshTokens();
    if (token == null) {
      await _expireSession();
      return handler.next(err);
    }

    try {
      final retried = await _replay(request, token);
      handler.resolve(retried);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  /// Single-flight refresh: concurrent callers await the same future.
  Future<String?> _refreshTokens() {
    return _refreshCall ??= _doRefresh().whenComplete(() {
      _refreshCall = null;
    });
  }

  Future<String?> _doRefresh() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await _tokenStorage.clear();
      return null;
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
        throw const FormatException('Refresh response missing tokens');
      }

      // Both tokens rotate on every refresh.
      await _tokenStorage.writeAccessToken(access);
      await _tokenStorage.writeRefreshToken(rotated);
      return access;
    } catch (_) {
      await _tokenStorage.clear();
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

  Future<void> _expireSession() async {
    await _tokenStorage.clear();
    if (!_sessionExpired.isClosed) _sessionExpired.add(null);
  }

  bool _isRefreshCall(RequestOptions options) =>
      options.path.endsWith(ApiPaths.refresh);

  bool _isSessionProbe(RequestOptions options) =>
      options.path.endsWith(ApiPaths.me);
}
