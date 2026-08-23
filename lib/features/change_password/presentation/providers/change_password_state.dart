import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'change_password_state.freezed.dart';

/// Everything the change-password screen renders from. The widget holds no
/// state of its own beyond its TextEditingControllers and FocusNodes.
@freezed
class ChangePasswordState with _$ChangePasswordState {
  const ChangePasswordState._();

  const factory ChangePasswordState({
    @Default('') String currentPassword,
    @Default('') String newPassword,
    @Default('') String confirmPassword,
    @Default(true) bool obscureCurrent,
    @Default(true) bool obscureNew,
    @Default(true) bool obscureConfirm,
    @Default(null) String? currentError,
    @Default(null) String? newError,
    @Default(null) String? confirmError,

    /// `true` once the password has actually been changed.
    @Default(AsyncValue.data(false)) AsyncValue<bool> submission,

    /// Bumped when the current-password field must be re-typed, i.e. the
    /// server rejected the one that was entered. The page watches it and
    /// clears its controller.
    @Default(0) int currentPasswordClearTick,
  }) = _ChangePasswordState;

  bool get isSubmitting => submission.isLoading;

  bool get succeeded => submission.valueOrNull == true;

  /// All three fields filled and nothing in flight — matches the login
  /// screen's rule so the two forms behave the same way.
  bool get canSubmit =>
      currentPassword.isNotEmpty &&
      newPassword.isNotEmpty &&
      confirmPassword.isNotEmpty &&
      !isSubmitting;
}
