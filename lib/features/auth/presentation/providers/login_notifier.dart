import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../../../core/utils/clock_provider.dart';
import '../../domain/auth_failure_x.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../auth_providers.dart';
import '../../data/datasources/remembered_email_store.dart';
import 'auth_session_notifier.dart';
import 'login_state.dart';

/// Owns all login-screen behaviour. The widget only forwards events here.
class LoginNotifier extends AutoDisposeNotifier<LoginState> {
  /// A successful login navigates away, which disposes this notifier while
  /// [submit] is still unwinding. Writing state after that throws.
  bool _disposed = false;

  /// The longest the form will hold the button for one answer. The backend's
  /// window is 15 minutes; a larger `Retry-After` is honoured up to here, and
  /// the next try gets a fresh answer. It also keeps a broken header from
  /// locking the form for days.
  static const Duration maxWait = Duration(hours: 1);

  /// Fires each time the minutes left on the login throttle change, and once
  /// more when the wait is over.
  Timer? _waitTimer;

  /// How much of the wait was left when it was last checked, and how long the
  /// running timer was set for. Together they bound the wait from above
  /// without trusting the device clock: when a timer of five minutes fires,
  /// at least five minutes have passed, whatever the clock now says.
  Duration _waitLeft = Duration.zero;
  Duration _tick = Duration.zero;

  @override
  LoginState build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _waitTimer?.cancel();
    });
    // "Remember my email" (#60): the saved email, with the box ticked.
    final saved = _store?.read();
    return saved == null
        ? const LoginState()
        : LoginState(email: saved, rememberMe: true);
  }

  /// The remembered-email store, or null when it cannot be built (no
  /// SharedPreferences, as in a test): the form then simply starts empty.
  RememberedEmailStore? get _store {
    try {
      return ref.read(rememberedEmailStoreProvider);
    } catch (_) {
      return null;
    }
  }

  void emailChanged(String value) {
    state = state.copyWith(email: value, emailError: null);
  }

  void passwordChanged(String value) {
    state = state.copyWith(password: value, passwordError: null);
  }

  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  /// Held while a sign-in is on its way: what it saves was decided when it
  /// was sent (#60), so the box must not say otherwise meanwhile.
  void toggleRememberMe() {
    if (state.isSubmitting) return;
    state = state.copyWith(rememberMe: !state.rememberMe);
  }

  /// Validates, signs in through the session notifier, and folds the result
  /// back into state.
  Future<void> submit() async {
    if (state.isSubmitting) return;

    // The server has said when it will listen again; another request before
    // then only earns another 429. A timer that fired late (the phone slept)
    // must not hold the user back, so the clock is asked first.
    syncWait();
    if (state.isWaiting) return;

    state = state.copyWith(
      emailError: null,
      passwordError: null,
      submission: const AsyncValue.loading(),
    );

    // Read now: a successful login takes the App off this screen, which
    // disposes this notifier before the login call returns, and `ref` is
    // gone then.
    final store = _store;
    final remember = state.rememberMe;
    final email = state.email;

    final result = await ref
        .read(authSessionProvider.notifier)
        .login(email: email, password: state.password);

    // Only a sign-in that worked changes what is remembered (#60), and it
    // must happen here, before the disposed check below.
    if (result.isSuccess && store != null) {
      unawaited(remember ? store.save(email) : store.clear());
    }

    if (_disposed) return;

    state = result.fold(
      _applyFailure,
      (session) => state.copyWith(submission: AsyncValue.data(session)),
    );
  }

  /// Field-level failures mark the input; everything else surfaces as a
  /// submission error for the page to show once.
  ///
  /// A credential rejection also empties the password field. A transport
  /// failure — including the backend's 429 login throttle, which is *not* a
  /// credential failure — leaves what the user typed alone.
  ///
  /// The login throttle (`429 TOO_MANY_LOGIN_ATTEMPTS`) that says how long to
  /// wait is not an error to show once: it starts the wait, and the page
  /// shows the minutes left under the button for as long as it lasts. A
  /// throttle with no `Retry-After` has nothing to count down and surfaces
  /// like any other failure, and so does any other failure that happens to
  /// carry a `Retry-After`: the line under the button speaks of wrong tries.
  LoginState _applyFailure(Failure failure) {
    final wait = _throttleWaitOf(failure);
    if (wait != null) {
      final capped = wait > maxWait ? maxWait : wait;
      _waitLeft = capped;
      _scheduleWaitTick(capped);
      return state.copyWith(
        retryAt: ref.read(clockProvider)().add(capped),
        waitMinutesLeft: _minutesLeft(capped),
        submission: const AsyncValue.data(null),
      );
    }

    // Field-scoped errors — from the client rules or from a 422 — mark the
    // input and leave both values alone.
    if (failure is ValidationFailure) {
      switch (failure.field) {
        case LoginFields.email:
          return state.copyWith(
            emailError: failure.message,
            submission: const AsyncValue.data(null),
          );
        case LoginFields.password:
          return state.copyWith(
            passwordError: failure.message,
            submission: const AsyncValue.data(null),
          );
      }
    }

    final base = failure.isCredentialFailure
        ? state.copyWith(
            password: '',
            passwordClearTick: state.passwordClearTick + 1,
          )
        : state;

    return base.copyWith(
      submission: AsyncValue.error(failure, StackTrace.current),
    );
  }

  /// How long the login throttle asked us to wait, or null when [failure] is
  /// not that throttle or did not say.
  static Duration? _throttleWaitOf(Failure failure) {
    if (failure is! NetworkFailure) return null;
    if (failure.errorCode != ApiErrorCodes.tooManyLoginAttempts) return null;
    return failure.retryAfter;
  }

  /// Brings the wait in line with the time: fewer minutes left, or over.
  ///
  /// The page calls this when the App comes back to the foreground: timers do
  /// not run while the phone sleeps, and the button is off while waiting, so
  /// nothing else would notice that the wait ended in the meantime.
  ///
  /// The clock can only shorten the wait. [elapsedAtLeast] is the time known
  /// to have passed since the last check (a timer's own length), so a clock
  /// set back cannot stretch the wait either.
  void syncWait({Duration elapsedAtLeast = Duration.zero}) {
    final retryAt = state.retryAt;
    if (retryAt == null) return;

    final now = ref.read(clockProvider)();
    final byClock = retryAt.difference(now);
    final byTimer = _waitLeft - elapsedAtLeast;
    final left = byClock < byTimer ? byClock : byTimer;

    if (left <= Duration.zero) {
      _waitTimer?.cancel();
      _waitTimer = null;
      _waitLeft = Duration.zero;
      state = state.copyWith(retryAt: null, waitMinutesLeft: 0);
      return;
    }

    _waitLeft = left;
    state = state.copyWith(
      // Restated from what is really left, so a clock that jumped back does
      // not come back to haunt the next check.
      retryAt: now.add(left),
      waitMinutesLeft: _minutesLeft(left),
    );
    _scheduleWaitTick(left);
  }

  /// Wakes up when the minutes left next change — the wait rarely ends on a
  /// whole minute, so the first tick comes after the odd seconds — and at the
  /// end of the wait.
  void _scheduleWaitTick(Duration left) {
    const minute = Duration(minutes: 1);
    final odd = Duration(
      microseconds: left.inMicroseconds % minute.inMicroseconds,
    );

    final tick = odd == Duration.zero ? minute : odd;
    _tick = tick;
    _waitTimer?.cancel();
    _waitTimer = Timer(tick, () {
      if (_disposed) return;
      syncWait(elapsedAtLeast: _tick);
    });
  }
}

/// A wait in whole minutes, rounded up and at least 1: with 61 seconds to go
/// the user is told 2 minutes, never 0.
int _minutesLeft(Duration left) {
  const minute = Duration.microsecondsPerMinute;
  final minutes = (left.inMicroseconds + minute - 1) ~/ minute;
  return minutes < 1 ? 1 : minutes;
}

final loginNotifierProvider =
    AutoDisposeNotifierProvider<LoginNotifier, LoginState>(LoginNotifier.new);
