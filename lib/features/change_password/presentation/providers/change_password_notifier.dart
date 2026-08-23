import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../auth/domain/auth_failure_x.dart';
import '../../../auth/domain/usecases/change_password_usecase.dart';
import '../../../auth/presentation/providers/auth_session_notifier.dart';
import 'change_password_state.dart';

/// Owns all change-password behaviour. The widget only forwards events here.
class ChangePasswordNotifier extends AutoDisposeNotifier<ChangePasswordState> {
  /// A successful change navigates away, which disposes this notifier while
  /// [submit] is still unwinding. Writing state after that throws.
  bool _disposed = false;

  @override
  ChangePasswordState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    return const ChangePasswordState();
  }

  void currentPasswordChanged(String value) {
    state = state.copyWith(currentPassword: value, currentError: null);
  }

  void newPasswordChanged(String value) {
    state = state.copyWith(newPassword: value, newError: null);
  }

  void confirmPasswordChanged(String value) {
    state = state.copyWith(confirmPassword: value, confirmError: null);
  }

  void toggleCurrentVisibility() {
    state = state.copyWith(obscureCurrent: !state.obscureCurrent);
  }

  void toggleNewVisibility() {
    state = state.copyWith(obscureNew: !state.obscureNew);
  }

  void toggleConfirmVisibility() {
    state = state.copyWith(obscureConfirm: !state.obscureConfirm);
  }

  /// Runs the four client rules, then the call. The session notifier is what
  /// actually clears `must_change_password`; this only reports the outcome.
  Future<void> submit() async {
    if (!state.canSubmit) return;

    state = state.copyWith(
      currentError: null,
      newError: null,
      confirmError: null,
      submission: const AsyncValue.loading(),
    );

    final result = await ref
        .read(authSessionProvider.notifier)
        .changePassword(
          currentPassword: state.currentPassword,
          newPassword: state.newPassword,
          confirmPassword: state.confirmPassword,
        );

    if (_disposed) return;

    state = result.fold(
      _applyFailure,
      (_) => state.copyWith(submission: const AsyncValue.data(true)),
    );
  }

  /// The one way off this screen without setting a password.
  Future<void> signOut() => ref.read(authSessionProvider.notifier).logout();

  /// Field-scoped failures mark their input. Anything else that reads as a
  /// credential problem lands under the current-password field — a rejected
  /// change is nearly always a wrong current password (the backend answers
  /// `400 PASSWORD_MISMATCH`). Transport failures surface as a one-off error.
  ChangePasswordState _applyFailure(Failure failure) {
    if (failure is ValidationFailure) {
      switch (failure.field) {
        case ChangePasswordFields.current:
          return state.copyWith(
            currentError: failure.message,
            submission: const AsyncValue.data(false),
          );
        case ChangePasswordFields.next:
          return state.copyWith(
            newError: failure.message,
            submission: const AsyncValue.data(false),
          );
        case ChangePasswordFields.confirm:
          return state.copyWith(
            confirmError: failure.message,
            submission: const AsyncValue.data(false),
          );
      }
    }

    if (failure.isCredentialFailure) {
      return state.copyWith(
        currentPassword: '',
        currentPasswordClearTick: state.currentPasswordClearTick + 1,
        currentError: failure.message,
        submission: const AsyncValue.data(false),
      );
    }

    return state.copyWith(
      submission: AsyncValue.error(failure, StackTrace.current),
    );
  }
}

final changePasswordNotifierProvider =
    AutoDisposeNotifierProvider<ChangePasswordNotifier, ChangePasswordState>(
      ChangePasswordNotifier.new,
    );
