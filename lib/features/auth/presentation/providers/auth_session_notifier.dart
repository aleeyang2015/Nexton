import 'dart:async';

import 'package:flutter/widgets.dart' show AppLifecycleListener;
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

    // Back from the background, `/auth/me` is read again: someone made head
    // of a department (or no longer) sees the Approvals place change
    // without signing in again.
    final lifecycle = _tryCreateLifecycleListener();
    ref.onDispose(() => lifecycle?.dispose());

    final result = await ref.read(restoreSessionUseCaseProvider)();
    restoring = false;

    final session = result.getOrElse(const AuthSession.unauthenticated());
    final reason = endedWhileRestoring;
    if (reason == null) return session;

    // The network layer gave up on the stored session while it was being
    // restored. Whatever the restore made of it, that session is gone.
    await ref.read(logoutUseCaseProvider)();
    // Its tokens are gone: the FCM token only (#52).
    unawaited(_signOffThisPhone(tokensLive: false));
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
      // The access token still works here: the phone is signed off in full.
      await _forceLogout(SessionEndReason.passwordChanged, tokensLive: true);
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

  /// Guarded because this runs in plain `test()` suites too, where no
  /// `WidgetsBinding` exists for the listener to register with.
  AppLifecycleListener? _tryCreateLifecycleListener() {
    try {
      // `onShow`, not `onResume`: back from the background, not every
      // dialog over the App (a location prompt during a punch, the
      // notification shade).
      return AppLifecycleListener(onShow: () => unawaited(refreshOnResume()));
    } catch (_) {
      return null;
    }
  }

  /// The App came back to the foreground: re-reads `/auth/me` when someone
  /// is signed in. Nothing is asked while signed out or still starting.
  ///
  /// One at a time: a second return while one is on its way asks nothing.
  Future<void> refreshOnResume() async {
    final current = state.valueOrNull;
    if (_refreshing ||
        current?.user == null ||
        current!.status == AuthStatus.unauthenticated ||
        current.status == AuthStatus.bootstrapping) {
      return;
    }
    _refreshing = true;
    try {
      await refreshProfile();
    } finally {
      _refreshing = false;
    }
  }

  bool _refreshing = false;

  /// Re-reads `/auth/me`: a role, module, permission or department-head
  /// change. A failure leaves the current session untouched, and so does an
  /// answer that lands after the session changed hands (signed out, or
  /// another user signed in): it must not bring a session back. The status
  /// stays, so a pending password change stays pending.
  Future<void> refreshProfile() async {
    final asked = state.valueOrNull?.user?.id;
    if (asked == null) return;
    final result = await ref.read(authRepositoryProvider).fetchProfile();
    final user = result.dataOrNull;
    if (user == null) return;

    final current = state.valueOrNull;
    if (current == null ||
        current.status == AuthStatus.unauthenticated ||
        current.user?.id != asked ||
        user.id != asked) {
      return;
    }
    state = AsyncValue.data(AuthSession(status: current.status, user: user));
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
  ///
  /// Before the tokens go, this phone is signed off for push (#52:
  /// [beforeSignOutProvider]), so a shared phone stops getting this user's
  /// pushes. That never stops the sign-out, and waits at most a few seconds.
  ///
  /// One at a time: a second tap while one is on its way gets that one.
  Future<void> logout() =>
      _loggingOut ??= _logout().whenComplete(() => _loggingOut = null);

  Future<void>? _loggingOut;

  Future<void> _logout() async {
    await _signOffThisPhone(tokensLive: true);
    await ref.read(logoutUseCaseProvider)();
    state = const AsyncValue.data(AuthSession.unauthenticated());
  }

  Future<void> _signOffThisPhone({required bool tokensLive}) async {
    try {
      await ref.read(beforeSignOutProvider)(tokensLive: tokensLive);
    } catch (_) {
      // Never stops a sign-out.
    }
  }

  /// A sign-out the user did not ask for. When the interceptor forced it the
  /// tokens are already gone; this clears the cached profile and the
  /// in-memory session, and keeps [reason] for the sign-in screen.
  ///
  /// Requests that were in flight together each report the same loss. Once
  /// the session is down, a repeat changes nothing: the first reason stands,
  /// and one the sign-in screen has already said is not said again.
  ///
  /// [tokensLive]: the access token still works (a failed re-login after a
  /// password change), so the phone is signed off in full first (#52).
  Future<void> _forceLogout(
    SessionEndReason reason, {
    bool tokensLive = false,
  }) async {
    final current = state.valueOrNull;
    if (current != null && current.status == AuthStatus.unauthenticated) {
      return;
    }

    if (tokensLive) await _signOffThisPhone(tokensLive: true);
    await ref.read(logoutUseCaseProvider)();
    state = AsyncValue.data(AuthSession.unauthenticated(endReason: reason));
    // The tokens are already gone: no `DELETE`, the FCM token only (#52).
    // After the sign-out, not before: reports of the same loss that arrive
    // together must find the session already down.
    if (!tokensLive) unawaited(_signOffThisPhone(tokensLive: false));
  }
}

final authSessionProvider =
    AsyncNotifierProvider<AuthSessionNotifier, AuthSession>(
      AuthSessionNotifier.new,
    );
