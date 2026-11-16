import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/auth_session.dart';

part 'login_state.freezed.dart';

/// Everything the login screen renders from. The widget holds no state
/// of its own beyond its TextEditingControllers.
@freezed
class LoginState with _$LoginState {
  const LoginState._();

  const factory LoginState({
    @Default('') String email,
    @Default('') String password,
    @Default(true) bool obscurePassword,
    @Default(false) bool rememberMe,
    @Default(null) String? emailError,
    @Default(null) String? passwordError,
    @Default(AsyncValue.data(null)) AsyncValue<AuthSession?> submission,

    /// Bumped whenever the password field must be emptied — a wrong-credentials
    /// answer from the server. The page watches it and clears its controller;
    /// a network blip (or a 429 throttle) never bumps it, so the typed
    /// password survives a retry.
    @Default(0) int passwordClearTick,

    /// When the login throttle lets this network try again: the moment a
    /// `429 TOO_MANY_LOGIN_ATTEMPTS` asked us to wait until, from its
    /// `Retry-After`. Null when nothing is being waited for; the notifier
    /// clears it as soon as the moment passes.
    @Default(null) DateTime? retryAt,

    /// Whole minutes left until [retryAt], rounded up and never below 1 while
    /// waiting. The notifier keeps it current; 0 when not waiting.
    @Default(0) int waitMinutesLeft,
  }) = _LoginState;

  /// True while the login request is in flight
  bool get isSubmitting => submission.isLoading;

  /// True while the server's login throttle is still running. The button is
  /// off and [waitMinutesLeft] says for how long.
  bool get isWaiting => retryAt != null;

  /// Set once login succeeded — the page listens for this to navigate
  AuthSession? get session => submission.valueOrNull;
}
