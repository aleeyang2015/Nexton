import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import 'secure_store.dart';

/// Where the session tokens live. Kept behind an interface so the backing
/// store can be swapped without touching the interceptor or the auth feature.
abstract class TokenStorage {
  Future<String?> readAccessToken();

  Future<String?> readRefreshToken();

  Future<void> writeAccessToken(String token);

  Future<void> writeRefreshToken(String token);

  /// Drops both tokens. Callers that also cache a profile clear it separately.
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
  Future<void> clear() async {
    _accessToken = null;
    await _store.delete(AppConstants.accessTokenKey);
    await _store.delete(AppConstants.refreshTokenKey);
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
