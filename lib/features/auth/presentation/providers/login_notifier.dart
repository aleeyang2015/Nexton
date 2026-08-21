import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/auth_failure_x.dart';
import '../../domain/usecases/login_usecase.dart';
import 'auth_session_notifier.dart';
import 'login_state.dart';

/// Owns all login-screen behaviour. The widget only forwards events here.
class LoginNotifier extends AutoDisposeNotifier<LoginState> {
  /// A successful login navigates away, which disposes this notifier while
  /// [submit] is still unwinding. Writing state after that throws.
  bool _disposed = false;

  @override
  LoginState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
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
  LoginState _applyFailure(Failure failure) {
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
}

final loginNotifierProvider =
    AutoDisposeNotifierProvider<LoginNotifier, LoginState>(LoginNotifier.new);
