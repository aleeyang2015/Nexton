import '../../../../core/utils/result.dart';
import '../entities/auth_session.dart';
import '../entities/user.dart';

/// Contract the presentation layer depends on.
/// The implementation lives in data/repositories.
abstract class AuthRepository {
  /// Exchange credentials for a session: writes both tokens, then loads the
  /// profile. Treated as atomic — a profile failure rolls the tokens back.
  FutureResult<AuthSession> login({
    required String email,
    required String password,
  });

  /// Cold start: resolve whatever is on disk into a session, revalidating
  /// against `GET /auth/me`.
  FutureResult<AuthSession> restoreSession();

  /// Re-read the current profile (`GET /auth/me`) and refresh the cache.
  FutureResult<User> fetchProfile();

  /// Set a new password. Invalidates every outstanding refresh token
  /// server-side, so the caller must keep using the session it already has.
  FutureResult<Unit> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Drop the current session. There is no logout endpoint — this is local
  /// teardown only, and the refresh token is left to lapse server-side.
  FutureResult<Unit> logout();

  /// The cached profile, or null when nobody is signed in
  FutureResult<User?> currentUser();

  /// Fires when the network layer gives up on the session (failed refresh, or
  /// a refreshed token that still can't read `/auth/me`).
  Stream<void> get onSessionExpired;
}
