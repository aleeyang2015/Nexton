import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/user.dart';

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
    @Default(AsyncValue.data(null)) AsyncValue<User?> submission,
  }) = _LoginState;

  /// True while the login request is in flight
  bool get isSubmitting => submission.isLoading;

  /// Set once login succeeded — the page listens for this to navigate
  User? get signedInUser => submission.valueOrNull;
}
