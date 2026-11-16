import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/clock_provider.dart';
import '../../domain/auth_failure_x.dart';
import '../../domain/usecases/login_usecase.dart';
import 'auth_session_notifier.dart';
import 'login_state.dart';

/// Owns all login-screen behaviour. The widget only forwards events here.
class LoginNotifier extends AutoDisposeNotifier<LoginState> {
  /// A successful login navigates away, which disposes this notifier while
  /// [submit] is still unwinding. Writing state after that throws.
  bool _disposed = false;

  /// Fires each time the minutes left on the login throttle change, and once
  /// more when the wait is over.
  Timer? _waitTimer;

  @override
  LoginState build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _waitTimer?.cancel();
    });
    return const LoginState();
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

  void toggleRememberMe() {
    state = state.copyWith(rememberMe: !state.rememberMe);
  }

  /// Validates, signs in through the session notifier, and folds the result
  /// back into state.
  Future<void> submit() async {
    if (state.isSubmitting) return;

    // The server has said when it will listen again; another request before
    // then only earns another 429. A timer that fired late (the phone slept)
    // must not hold the user back, so the clock has the last word.
    _refreshWait();
    if (state.isWaiting) return;

    state = state.copyWith(
      emailError: null,
      passwordError: null,
      submission: const AsyncValue.loading(),
    );

    final result = await ref
        .read(authSessionProvider.notifier)
        .login(email: state.email, password: state.password);

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
  /// A throttle that says how long to wait is not an error to show once: it
  /// starts the wait, and the page shows the minutes left under the button
  /// for as long as it lasts. A throttle with no `Retry-After` has nothing to
  /// count down and surfaces like any other failure.
  LoginState _applyFailure(Failure failure) {
    final wait = failure.retryAfter;
    if (wait != null) {
      final retryAt = ref.read(clockProvider)().add(wait);
      _scheduleWaitTick(wait);
      return state.copyWith(
        retryAt: retryAt,
        waitMinutesLeft: _minutesLeft(wait),
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

  /// Brings the wait in line with the clock: fewer minutes left, or over.
  void _refreshWait() {
    final retryAt = state.retryAt;
    if (retryAt == null) return;

    final left = retryAt.difference(ref.read(clockProvider)());
    if (left <= Duration.zero) {
      _waitTimer?.cancel();
      _waitTimer = null;
      state = state.copyWith(retryAt: null, waitMinutesLeft: 0);
      return;
    }

    state = state.copyWith(waitMinutesLeft: _minutesLeft(left));
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

    _waitTimer?.cancel();
    _waitTimer = Timer(odd == Duration.zero ? minute : odd, () {
      if (_disposed) return;
      _refreshWait();
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
