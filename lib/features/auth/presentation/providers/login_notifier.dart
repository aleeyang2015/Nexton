import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../auth_providers.dart';
import '../../domain/usecases/login_usecase.dart';
import 'login_state.dart';

/// Owns all login-screen behaviour. The widget only forwards events here.
class LoginNotifier extends AutoDisposeNotifier<LoginState> {
  @override
  LoginState build() => const LoginState();

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

  /// Validates, calls the use case, and folds the result back into state.
  Future<void> submit() async {
    if (state.isSubmitting) return;

    state = state.copyWith(
      emailError: null,
      passwordError: null,
      submission: const AsyncValue.loading(),
    );

    final result = await ref.read(loginUseCaseProvider)(
      LoginParams(email: state.email, password: state.password),
    );

    state = result.fold(
      _applyFailure,
      (user) => state.copyWith(submission: AsyncValue.data(user)),
    );
  }

  /// Field-level failures mark the input; everything else surfaces as a
  /// submission error for the page to show once.
  LoginState _applyFailure(Failure failure) {
    if (failure is ValidationFailure) {
      return switch (failure.field) {
        LoginFields.email => state.copyWith(
            emailError: failure.message,
            submission: const AsyncValue.data(null),
          ),
        LoginFields.password => state.copyWith(
            passwordError: failure.message,
            submission: const AsyncValue.data(null),
          ),
        _ => state.copyWith(
            submission: AsyncValue.error(failure, StackTrace.current),
          ),
      };
    }

    return state.copyWith(
      submission: AsyncValue.error(failure, StackTrace.current),
    );
  }
}

final loginNotifierProvider =
    AutoDisposeNotifierProvider<LoginNotifier, LoginState>(LoginNotifier.new);
