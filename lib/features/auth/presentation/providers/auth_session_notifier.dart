import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/session_end_reason.dart';
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
    // The network layer clears the tokens and signals here when the server
    // refuses a refresh, a refreshed token still can't read the profile, or
    // the company is switched off.
    //
    // On a cold start that signal arrives while the restore below is still
    // waiting on `/auth/me`, and the restore then answers with a plain
    // "unauthenticated". The reason is kept aside so the sign-in screen still
    // gets it: this is how most dead sessions are found.
    SessionEndReason? endedWhileRestoring;
    var restoring = true;

    final subscription = ref
        .watch(authRepositoryProvider)
        .onSessionExpired
        .listen((reason) {
          if (restoring) {
            endedWhileRestoring ??= reason;
            return;
          }
          _forceLogout(reason);
        });
    ref.onDispose(subscription.cancel);

    final result = await ref.read(restoreSessionUseCaseProvider)();
    restoring = false;

    final session = result.getOrElse(const AuthSession.unauthenticated());
    final reason = endedWhileRestoring;
    if (reason == null) return session;

    // The network layer gave up on the stored session while it was being
    // restored. Whatever the restore made of it, that session is gone.
    await ref.read(logoutUseCaseProvider)();
    return AuthSession.unauthenticated(endReason: reason);
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
  /// The backend stamps `password_set_at`, which kills every refresh token
  /// issued before the change, while the access token keeps working until it
  /// expires. Left alone, the session would die mid-task weeks later. So this
  /// signs in again at once with the user's email and the new password, which
  /// stores a pair that still refreshes and reloads the profile. The new
  /// password is held only for that call.
  ///
  /// When that sign-in fails the password *has* changed, so the session ends
  /// with [SessionEndReason.passwordChanged] and the sign-in screen asks for
  /// the new one.
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

    final email = state.valueOrNull?.user?.email;
    final session = email == null
        ? null
        : (await ref.read(loginUseCaseProvider)(
            LoginParams(email: email, password: newPassword),
          )).dataOrNull;

    if (session == null || !session.hasSession) {
      await _forceLogout(SessionEndReason.passwordChanged);
      return result;
    }

    state = AsyncValue.data(session);
    return result;
  }

  /// The sign-in screen has told the user why the last session ended.
  void clearEndReason() {
    final current = state.valueOrNull;
    if (current == null || current.endReason == null) return;
    state = const AsyncValue.data(AuthSession.unauthenticated());
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

  /// A sign-out the user did not ask for. When the interceptor forced it the
  /// tokens are already gone; this clears the cached profile and the
  /// in-memory session, and keeps [reason] for the sign-in screen.
  ///
  /// Requests that were in flight together each report the same loss. Once
  /// the session is down, a repeat changes nothing: the first reason stands,
  /// and one the sign-in screen has already said is not said again.
  Future<void> _forceLogout(SessionEndReason reason) async {
    final current = state.valueOrNull;
    if (current != null && current.status == AuthStatus.unauthenticated) {
      return;
    }

    await ref.read(logoutUseCaseProvider)();
    state = AsyncValue.data(AuthSession.unauthenticated(endReason: reason));
  }
}

final authSessionProvider =
    AsyncNotifierProvider<AuthSessionNotifier, AuthSession>(
      AuthSessionNotifier.new,
    );
