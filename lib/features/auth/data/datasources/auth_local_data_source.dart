import 'dart:convert';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/secure_store.dart';
import '../../../../core/network/token_storage.dart';
import '../models/user_model.dart';

/// On-device session: the token pair, a cached copy of the profile, and the
/// pending-password-change flag.
///
/// The cached profile is a **render optimisation only** — the source of truth
/// is the token store and the network. A cache miss just means the cold start
/// blocks on `/auth/me` instead of painting optimistically.
///
/// The `must_change_password` flag is different: it is the **only** record of
/// a requirement the backend reports exactly once, at login. Persisting it is
/// what stops an app restart from walking around the change-password screen.
abstract class AuthLocalDataSource {
  Future<UserModel?> readUser();

  Future<void> writeUser(UserModel user);

  /// [expiresAt] is the access token's expiry when the response reported one.
  /// Passing null clears any expiry a previous session left behind, so a
  /// stored expiry can never describe a token that is no longer there.
  Future<void> writeTokens({
    required String accessToken,
    required String refreshToken,
    DateTime? expiresAt,
  });

  /// True when an access token is on disk — the cheap "might be signed in"
  /// check the cold start runs before touching the network.
  Future<bool> hasTokens();

  /// The saved refresh token, for the server's logout (#56).
  Future<String?> readRefreshToken();

  Future<bool> readMustChangePassword();

  Future<void> writeMustChangePassword(bool value);

  /// Drops the tokens, the access-token expiry, the cached profile and the
  /// pending-change flag.
  Future<void> clear();

  /// [clear], but only while [refreshToken] is still the saved refresh
  /// token: one sign-in's leftovers are removed, never a sign-in made since.
  /// False, and nothing cleared, when it is not.
  Future<bool> clearIfRefreshIs(String refreshToken);
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SecureStore _store;
  final TokenStorage _tokenStorage;

  AuthLocalDataSourceImpl({
    required SecureStore store,
    required TokenStorage tokenStorage,
  }) : _store = store,
       _tokenStorage = tokenStorage;

  @override
  Future<UserModel?> readUser() async {
    final raw = await _store.read(AppConstants.cachedUserKey);
    if (raw == null) return null;

    try {
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // A stale cache written by an older model shape is not worth an error.
      await _store.delete(AppConstants.cachedUserKey);
      return null;
    }
  }

  @override
  Future<void> writeUser(UserModel user) =>
      _store.write(AppConstants.cachedUserKey, jsonEncode(user.toJson()));

  @override
  Future<void> writeTokens({
    required String accessToken,
    required String refreshToken,
    DateTime? expiresAt,
  }) =>
      // One step of the storage: a renewal of the last sign-in that answers
      // now cannot land in the middle of this one (#71).
      _tokenStorage.saveSignIn(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: expiresAt,
      );

  @override
  Future<bool> hasTokens() async {
    final token = await _tokenStorage.readAccessToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<String?> readRefreshToken() => _tokenStorage.readRefreshToken();

  @override
  Future<bool> readMustChangePassword() async =>
      await _store.read(AppConstants.mustChangePasswordKey) == 'true';

  @override
  Future<void> writeMustChangePassword(bool value) => value
      ? _store.write(AppConstants.mustChangePasswordKey, 'true')
      : _store.delete(AppConstants.mustChangePasswordKey);

  @override
  Future<void> clear() async {
    await _tokenStorage.clear();
    await _clearProfile();
  }

  @override
  Future<bool> clearIfRefreshIs(String refreshToken) async {
    // The check and the token clear are one step of the storage (#71), so
    // a sign-in saved meanwhile cannot land between them and be wiped.
    if (!await _tokenStorage.clearIfRefreshIs(refreshToken)) return false;
    await _clearProfile();
    return true;
  }

  Future<void> _clearProfile() async {
    await _store.delete(AppConstants.cachedUserKey);
    await _store.delete(AppConstants.mustChangePasswordKey);
  }
}
