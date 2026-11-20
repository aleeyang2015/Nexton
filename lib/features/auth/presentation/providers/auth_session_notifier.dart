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
          // Held while the password is being changed: see [changePassword].
          if (_changingPassword) {
            _endedWhileChangingPassword ??= reason;
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
  ///
  /// From the moment the server takes the new password until that sign-in
  /// has stored its pair, the refresh token on the phone is a dead one. A
  /// request refused in that gap makes the network layer try it, be refused,
  /// and report the session lost (#91). Such a report is held while this
  /// runs, not acted on, so the user is never shown the sign-in screen for
  /// having changed their password (#5). The network layer clears the
  /// stored tokens as it reports, which can land on the pair the sign-in
  /// has just stored: after a held report the session is read back from
  /// what is stored, and stands only if it is still there.
  ///
  /// The user's own "Sign out" is not held: a session the user ended while
  /// this ran stays ended (#93, see [_leftDuringChange]).
  Future<Result<Unit>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _changingPassword = true;
    _endedWhileChangingPassword = null;
    try {
      return await _changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
    } finally {
      _changingPassword = false;
      _endedWhileChangingPassword = null;
    }
  }

  /// True while [changePassword] runs.
  bool _changingPassword = false;

  /// The session-end report held while [changePassword] runs, if one came.
  SessionEndReason? _endedWhileChangingPassword;

  Future<Result<Unit>> _changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final signedInAs = state.valueOrNull?.user?.id;
    final result = await ref.read(changePasswordUseCaseProvider)(
      ChangePasswordParams(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      ),
    );

    if (result.isFailure) {
      // The password did not change, so a report held meanwhile was about
      // the session itself: it did end.
      final held = _endedWhileChangingPassword;
      if (held != null) await _forceLogout(held);
      return result;
    }

    final email = state.valueOrNull?.user?.email;
    // Asked by the sign-in once the server has answered, before it stores
    // anything: has the user left meanwhile (#93)? Then that sign-in ends
    // its own new pair on the server and stores nothing. It is the one
    // place sure to hold that pair: a sign-out already on its way may have
    // read the old refresh token.
    var abandoned = false;
    bool userLeft() =>
        abandoned = _loggingOut != null || !_stillSignedInAs(signedInAs);
    final session = email == null
        ? null
        : (await ref.read(loginUseCaseProvider)(
            LoginParams(
              email: email,
              password: newPassword,
              abandonIf: userLeft,
            ),
          )).dataOrNull;

    // Ended by itself, stored nowhere: nothing more to end, and the user,
    // who signed out, is not told the password change signed them out.
    if (abandoned) return result;

    // The user left after the sign-in stored its pair (#93), or while a
    // failed one was on its way.
    if (await _leftDuringChange(signedInAs)) return result;

    if (session == null || !session.hasSession) {
      final held = _endedWhileChangingPassword;
      if (held == null) {
        // The access token still works here: the phone is signed off in
        // full.
        await _forceLogout(SessionEndReason.passwordChanged, tokensLive: true);
      } else {
        // The network layer already cleared the tokens. Its reason is the
        // one to show when it says more than "expired" (the account or the
        // company was switched off); otherwise the password change is why.
        await _forceLogout(
          held == SessionEndReason.expired
              ? SessionEndReason.passwordChanged
              : held,
        );
      }
      return result;
    }

    if (_endedWhileChangingPassword == null) {
      state = AsyncValue.data(session);
      return result;
    }

    // Signed in again, and a report was held: it was the dead refresh
    // token's. Its clearing of the tokens may have landed on the new pair,
    // so the session is the one that can be read back from what is stored.
    final stored = (await ref.read(restoreSessionUseCaseProvider)()).getOrElse(
      const AuthSession.unauthenticated(),
    );
    // Or while the session was being read back.
    if (await _leftDuringChange(signedInAs)) return result;
    if (!stored.hasSession) {
      await _forceLogout(SessionEndReason.passwordChanged);
      return result;
    }
    state = AsyncValue.data(stored);
    return result;
  }

  /// True when the user signed out while [changePassword] was waiting
  /// (#93): "Sign out" on the forced-change page stays open while the change
  /// is sent. The new session is then not published, so a sign-out is never
  /// undone by the change finishing.
  ///
  /// A sign-in that answers after the user left ends its own pair and
  /// stores nothing ([changePassword]'s `abandonIf`). One that stored its
  /// pair before they left: a sign-out still on its way reads that pair and
  /// ends it; one that has finished cannot, so the pair is ended on the
  /// server and cleared here, and no working sign-in is left on a phone its
  /// user has walked away from. The state stays as the sign-out left it.
  ///
  /// The phone was not registered for push under the new sign-in (that
  /// happens when a session is published), so there is no row to remove.
  /// Should someone else be signed in by now, nothing is touched.
  Future<bool> _leftDuringChange(String? signedInAs) async {
    if (_loggingOut != null) return true;
    if (_stillSignedInAs(signedInAs)) return false;

    final current = state.valueOrNull;
    if (current == null || !current.hasSession) {
      await ref.read(logoutUseCaseProvider)(endSession: true);
    }
    return true;
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

  /// User-initiated sign-out: the phone's push row, then the server ends
  /// this phone's sign-in (#56), then the local teardown.
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

  /// The order matters: the phone's push row goes first (#52), then the
  /// server ends the sign-in (#56) — after that the access token is refused
  /// — then the phone's copy is cleared. Both server calls need the tokens.
  Future<void> _logout() async {
    final signedInAs = state.valueOrNull?.user?.id;
    await _signOffThisPhone(tokensLive: true);
    // The sign-off can take seconds: a forced sign-out meanwhile already
    // ended this session, and someone may have signed in since. Their
    // sign-in is not this sign-out's to end, on the server or the phone.
    if (!_stillSignedInAs(signedInAs)) return;
    await ref.read(logoutUseCaseProvider)(endSession: true);
    state = const AsyncValue.data(AuthSession.unauthenticated());
  }

  /// True while the session is still the one signed in as [userId].
  bool _stillSignedInAs(String? userId) {
    final session = state.valueOrNull;
    return session != null &&
        session.hasSession &&
        session.user?.id == userId;
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

    if (tokensLive) {
      final signedInAs = current?.user?.id;
      await _signOffThisPhone(tokensLive: true);
      // As in [_logout]: a session ended meanwhile is not this one's to end.
      if (!_stillSignedInAs(signedInAs)) return;
    }
    // The tokens still work only after a failed re-login: the server ends
    // that sign-in too (#56). Otherwise they are already gone.
    await ref.read(logoutUseCaseProvider)(endSession: tokensLive);
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
