import '../../../../core/network/session_end_reason.dart';
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
  /// server-side, so the caller signs in again with the new password to get a
  /// pair that still refreshes.
  FutureResult<Unit> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Drop the current session on the phone. With [endSession] the server
  /// ends this phone's sign-in first (#56), so a copied refresh token stops
  /// working; that call never stops the local sign-out.
  FutureResult<Unit> logout({bool endSession = false});

  /// The cached profile, or null when nobody is signed in
  FutureResult<User?> currentUser();

  /// Fires when the network layer gives up on the session (a refused refresh,
  /// a refreshed token that still can't read `/auth/me`, a switched-off
  /// company), with the reason to tell the user.
  Stream<SessionEndReason> get onSessionExpired;
}
