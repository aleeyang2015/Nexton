import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/result.dart';
import '../../auth_providers.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/usecases/change_password_usecase.dart';
import '../../domain/usecases/login_usecase.dart';

/// Owns the session state machine for the whole app: who is signed in, and
/// which shell the router is allowed to show.
///
/// Screens never call the auth use cases directly — they go through here, so
/// there is exactly one place that can change the session.
class AuthSessionNotifier extends AsyncNotifier<AuthSession> {
  @override
  Future<AuthSession> build() async {
    // The network layer clears the tokens and signals here when a refresh
    // fails or a refreshed token still can't read the profile.
    final subscription = ref
        .watch(authRepositoryProvider)
        .onSessionExpired
        .listen((_) => _forceLogout());
    ref.onDispose(subscription.cancel);

    final result = await ref.read(restoreSessionUseCaseProvider)();
    return result.getOrElse(const AuthSession.unauthenticated());
  }

  /// Signs in and, on success, publishes the new session. The [Result] goes
  /// back to the caller so the login form can mark the offending field.
  Future<Result<AuthSession>> login({
    required String email,
    required String password,
  }) async {
    final result = await ref.read(loginUseCaseProvider)(
      LoginParams(email: email, password: password),
    );

    final session = result.dataOrNull;
    if (session != null) state = AsyncValue.data(session);

    return result;
  }

  /// Sets a new password and, on success, releases the session out of
  /// [AuthStatus.mustChangePassword].
  ///
  /// The backend stamps `password_set_at`, which kills every outstanding
  /// refresh token — the current access token keeps working until it expires,
  /// and the next 401 will ask for a fresh login.
  Future<Result<Unit>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final result = await ref.read(changePasswordUseCaseProvider)(
      ChangePasswordParams(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      ),
    );

    if (result.isFailure) return result;

    // Pick up anything the change altered on the profile. A failure here must
    // not strand the user on the change-password screen, so fall back to the
    // profile already in hand.
    final refreshed = await ref.read(authRepositoryProvider).fetchProfile();
    final user = refreshed.dataOrNull ?? state.valueOrNull?.user;

    state = user == null
        // No profile to release into — safest exit is a fresh login.
        ? const AsyncValue.data(AuthSession.unauthenticated())
        : AsyncValue.data(AuthSession.signedIn(user));

    return result;
  }

  /// Re-reads `/auth/me`. Used to pick up a role or module change after a
  /// token refresh — a failure leaves the current session untouched.
  Future<void> refreshProfile() async {
    final result = await ref.read(authRepositoryProvider).fetchProfile();
    final user = result.dataOrNull;
    if (user == null) return;

    final current = state.valueOrNull;
    state = AsyncValue.data(
      AuthSession(
        status: current?.status ?? AuthStatus.authenticated,
        user: user,
      ),
    );
  }

  /// User-initiated sign-out. There is no logout endpoint; this is local
  /// teardown only.
  ///
  /// Every feature's session-scoped provider (profile, attendance, leave,
  /// salary — see their `.autoDispose` declarations) is watched only by
  /// widgets under the signed-in shell. The moment this state flips
  /// unauthenticated, the router tears that whole shell down, each provider
  /// loses its last watcher, and Riverpod disposes it on its own — so the
  /// next sign-in rebuilds every one of them from scratch, same as a cold
  /// app start. Nothing here needs to invalidate them by hand.
  Future<void> logout() async {
    await ref.read(logoutUseCaseProvider)();
    state = const AsyncValue.data(AuthSession.unauthenticated());
  }

  /// Interceptor-forced sign-out. The tokens are already gone by the time
  /// this runs; this clears the cached profile and the in-memory session.
  Future<void> _forceLogout() async {
    await ref.read(logoutUseCaseProvider)();
    state = const AsyncValue.data(AuthSession.unauthenticated());
  }
}

final authSessionProvider =
    AsyncNotifierProvider<AuthSessionNotifier, AuthSession>(
      AuthSessionNotifier.new,
    );
