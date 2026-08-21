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
  }) = _LoginState;

  /// True while the login request is in flight
  bool get isSubmitting => submission.isLoading;

  /// Set once login succeeded — the page listens for this to navigate
  AuthSession? get session => submission.valueOrNull;
}
