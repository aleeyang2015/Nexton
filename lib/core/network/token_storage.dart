import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import 'secure_store.dart';

/// Reads an `expires_at` off the wire — Unix **seconds**, as both
/// `/auth/login` and `/auth/refresh` report it (auth-login.md §2, §3).
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
  /// a 401 (auth-login.md §5) — so a null here is never a reason to treat a
  /// stored token as dead.
  Future<DateTime?> readAccessTokenExpiry();

  /// Records the expiry that came with the current access token. A null
  /// [expiry] drops any stored value, so an expiry can never outlive the token
  /// it described.
  Future<void> writeAccessTokenExpiry(DateTime? expiry);

  /// Drops both tokens and the access-token expiry. Callers that also cache a
  /// profile clear it separately.
  Future<void> clear();
}

/// Keychain/Keystore-backed token storage, as auth.md requires. Tokens never
/// touch SharedPreferences — see [LegacySessionMigration] for the one-time
/// move of anything an older build left there.
class SecureTokenStorage implements TokenStorage {
  final SecureStore _store;

  /// In-memory mirror of the access token so the request interceptor never
  /// waits on the keychain for the header it attaches to every call.
  String? _accessToken;

  /// Mirror of the stored expiry, in the same raw Unix-seconds form it is
  /// written in.
  String? _expiresAt;

  SecureTokenStorage(this._store);

  @override
  Future<String?> readAccessToken() async =>
      _accessToken ??= await _store.read(AppConstants.accessTokenKey);

  @override
  Future<String?> readRefreshToken() =>
      _store.read(AppConstants.refreshTokenKey);

  @override
  Future<void> writeAccessToken(String token) async {
    _accessToken = token;
    await _store.write(AppConstants.accessTokenKey, token);
  }

  @override
  Future<void> writeRefreshToken(String token) =>
      _store.write(AppConstants.refreshTokenKey, token);

  @override
  Future<DateTime?> readAccessTokenExpiry() async {
    final raw = _expiresAt ??= await _store.read(AppConstants.expiresAtKey);
    return tokenExpiryFromUnixSeconds(raw);
  }

  @override
  Future<void> writeAccessTokenExpiry(DateTime? expiry) async {
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
  Future<void> clear() async {
    _accessToken = null;
    _expiresAt = null;
    await _store.delete(AppConstants.accessTokenKey);
    await _store.delete(AppConstants.refreshTokenKey);
    await _store.delete(AppConstants.expiresAtKey);
  }
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
