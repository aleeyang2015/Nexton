import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import 'secure_store.dart';

/// Reads an `expires_at` off the wire — Unix **seconds**, as both
/// `/auth/login` and `/auth/refresh` report it (the backend's
/// `docs/api/auth-login.md`).
///
/// Returns null for a missing, malformed or non-positive value: that is an
/// *unknown* expiry, which is not the same as an expiry of "now". Shared by
/// the login model and the refresh handling in [AuthInterceptor], which parse
/// the same field on either side of the layer boundary.
DateTime? tokenExpiryFromUnixSeconds(dynamic value) {
  final seconds = value is num ? value.toInt() : int.tryParse('${value ?? ''}');
  if (seconds == null || seconds <= 0) return null;

  return DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
}

/// Where the session tokens live. Kept behind an interface so the backing
/// store can be swapped without touching the interceptor or the auth feature.
abstract class TokenStorage {
  Future<String?> readAccessToken();

  Future<String?> readRefreshToken();

  Future<void> writeAccessToken(String token);

  Future<void> writeRefreshToken(String token);

  /// When the stored access token expires, or null when the server never said.
  ///
  /// Nothing refreshes off this clock — the app still refreshes reactively on
  /// a 401 (the backend's `docs/api/auth-login.md`, token lifecycle) — so a
  /// null here is never a reason to treat a stored token as dead.
  Future<DateTime?> readAccessTokenExpiry();

  /// Records the expiry that came with the current access token. A null
  /// [expiry] drops any stored value, so an expiry can never outlive the token
  /// it described.
  Future<void> writeAccessTokenExpiry(DateTime? expiry);

  /// Drops both tokens and the access-token expiry. Callers that also cache a
  /// profile clear it separately.
  Future<void> clear();

  /// Stores a sign-in's tokens and the access token's expiry together.
  Future<void> saveSignIn({
    required String accessToken,
    required String refreshToken,
    DateTime? expiresAt,
  });

  /// Stores a renewal's tokens, but only while [sentRefreshToken] is still
  /// the saved refresh token. False, and nothing written, when it is not.
  Future<bool> saveRenewed({
    required String sentRefreshToken,
    required String accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    void Function(String? previousAccessToken)? onAccepted,
  });

  /// [clear], but only while [sentRefreshToken] is still the saved refresh
  /// token. False, and nothing cleared, when it is not.
  Future<bool> clearIfRefreshIs(String sentRefreshToken);
}

/// Keychain/Keystore-backed token storage, as auth.md requires. Tokens never
/// touch SharedPreferences — see [LegacySessionMigration] for the one-time
/// move of anything an older build left there.
///
/// One keychain operation at a time (#71): every read that misses the
/// in-memory copy, every write and the clear run in turn, so their steps
/// never interleave. A sign-out's clear is never cut into by a renewal's
/// "is this still the same sign-in?" check and its writes, a refused
/// renewal's clear never wipes the next user's sign-in, and a first read
/// never brings back a token the clear is deleting.
class SecureTokenStorage implements TokenStorage {
  final SecureStore _store;

  /// In-memory mirror of the access token so the request interceptor never
  /// waits on the keychain for the header it attaches to every call.
  String? _accessToken;

  /// Mirror of the stored expiry, in the same raw Unix-seconds form it is
  /// written in.
  String? _expiresAt;

  /// Done when the last keychain operation queued has finished; null while
  /// none is queued, so an idle storage starts the next one at once and
  /// never waits on a future from an earlier zone.
  Future<void>? _tail;

  SecureTokenStorage(this._store);

  /// Runs [step] once every operation queued before it has finished. A
  /// step must not call another public method of this class (it would wait
  /// on itself): it uses the `_…Now` helpers.
  Future<T> _serial<T>(Future<T> Function() step) async {
    final previous = _tail;
    final done = Completer<void>();
    _tail = done.future;
    try {
      if (previous != null) await previous;
      return await step();
    } finally {
      if (identical(_tail, done.future)) _tail = null;
      done.complete();
    }
  }

  @override
  Future<String?> readAccessToken() async {
    final cached = _accessToken;
    if (cached != null) return cached;
    return _serial(_readAccessNow);
  }

  Future<String?> _readAccessNow() async =>
      _accessToken ??= await _store.read(AppConstants.accessTokenKey);

  @override
  Future<String?> readRefreshToken() =>
      _serial(() => _store.read(AppConstants.refreshTokenKey));

  @override
  Future<void> writeAccessToken(String token) => _serial(() async {
    _accessToken = token;
    await _store.write(AppConstants.accessTokenKey, token);
  });

  @override
  Future<void> writeRefreshToken(String token) =>
      _serial(() => _store.write(AppConstants.refreshTokenKey, token));

  @override
  Future<DateTime?> readAccessTokenExpiry() async {
    final raw =
        _expiresAt ??
        await _serial(
          () async =>
              _expiresAt ??= await _store.read(AppConstants.expiresAtKey),
        );
    return tokenExpiryFromUnixSeconds(raw);
  }

  @override
  Future<void> writeAccessTokenExpiry(DateTime? expiry) =>
      _serial(() => _writeExpiryNow(expiry));

  Future<void> _writeExpiryNow(DateTime? expiry) async {
    if (expiry == null) {
      _expiresAt = null;
      await _store.delete(AppConstants.expiresAtKey);
      return;
    }

    final raw = '${expiry.toUtc().millisecondsSinceEpoch ~/ 1000}';
    _expiresAt = raw;
    await _store.write(AppConstants.expiresAtKey, raw);
  }

  @override
  Future<void> clear() {
    // Dropped from memory at once, and again when the clear's turn comes.
    // A renewal queued before it still runs first and may put its token
    // back in memory meanwhile, for the same user's requests only; the
    // clear then wins, in memory and on the keychain.
    _accessToken = null;
    _expiresAt = null;
    return _serial(_clearNow);
  }

  Future<void> _clearNow() async {
    _accessToken = null;
    _expiresAt = null;
    await _store.delete(AppConstants.accessTokenKey);
    await _store.delete(AppConstants.refreshTokenKey);
    await _store.delete(AppConstants.expiresAtKey);
  }

  @override
  Future<void> saveSignIn({
    required String accessToken,
    required String refreshToken,
    DateTime? expiresAt,
  }) => _serial(() async {
    // The keychain first: a write it refuses leaves memory as it was.
    await _store.write(AppConstants.accessTokenKey, accessToken);
    await _store.write(AppConstants.refreshTokenKey, refreshToken);
    await _writeExpiryNow(expiresAt);
    _accessToken = accessToken;
  });

  @override
  Future<bool> saveRenewed({
    required String sentRefreshToken,
    required String accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    void Function(String? previousAccessToken)? onAccepted,
  }) => _serial(() async {
    final saved = await _store.read(AppConstants.refreshTokenKey);
    if (saved != sentRefreshToken) return false;
    final previous = await _readAccessNow();
    // The keychain first: a write it refuses (an iPhone keychain while the
    // phone is locked) leaves memory on the old token, not on one the
    // keychain does not have. Requests meanwhile carry the old token,
    // still this sign-in's.
    await _store.write(AppConstants.accessTokenKey, accessToken);
    if (refreshToken != null) {
      await _store.write(AppConstants.refreshTokenKey, refreshToken);
    }
    await _writeExpiryNow(expiresAt);
    // Told, and the copy in memory switched, in one go: no 401 can find
    // the new token without its line known (#89).
    onAccepted?.call(previous);
    _accessToken = accessToken;
    return true;
  });

  @override
  Future<bool> clearIfRefreshIs(String sentRefreshToken) => _serial(() async {
    final saved = await _store.read(AppConstants.refreshTokenKey);
    if (saved != sentRefreshToken) return false;
    await _clearNow();
    return true;
  });
}

/// One-time move of a session written by a build that kept it in
/// SharedPreferences. Runs at startup, before anything reads a token, so an
/// existing user is not signed out by the upgrade.
///
/// Anything it copies is deleted from SharedPreferences afterwards — a token
/// must not survive in plain storage.
class LegacySessionMigration {
  static const _legacyKeys = [
    AppConstants.accessTokenKey,
    AppConstants.refreshTokenKey,
    AppConstants.cachedUserKey,
    AppConstants.mustChangePasswordKey,
    // Key used before the access token was renamed.
    'auth_token',
  ];

  final SharedPreferences _prefs;
  final SecureStore _secureStore;

  LegacySessionMigration({
    required SharedPreferences prefs,
    required SecureStore secureStore,
  }) : _prefs = prefs,
       _secureStore = secureStore;

  Future<void> run() async {
    for (final key in _legacyKeys) {
      final value = _prefs.getString(key);
      if (value == null) continue;

      final target = key == 'auth_token' ? AppConstants.accessTokenKey : key;

      // Never clobber a session already in the keychain.
      if (await _secureStore.read(target) == null) {
        await _secureStore.write(target, value);
      }

      await _prefs.remove(key);
    }
  }
}
