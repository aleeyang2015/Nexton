import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/validation_codes.dart';
import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../repositories/auth_repository.dart';

/// Field names a [ValidationFailure] can point at, so the UI knows which
/// input to mark without matching on message strings.
class ChangePasswordFields {
  ChangePasswordFields._();

  static const String current = 'current_password';
  static const String next = 'new_password';
  static const String confirm = 'confirm_password';
}

/// The three inputs and the rules they must satisfy.
///
/// Rule order matters and matches auth.md exactly. Rule 3 (new must differ
/// from current) is a **client-only** guard — the backend would happily accept
/// the same password again.
class ChangePasswordParams extends BaseParams {
  final String currentPassword;
  final String newPassword;
  final String confirmPassword;

  ChangePasswordParams({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
  });

  @override
  Result<Unit> validate() {
    if (currentPassword.isEmpty) {
      return Result.failure(
        Failure.validation(
          message: ValidationCode.currentPasswordRequired,
          field: ChangePasswordFields.current,
        ),
      );
    }

    if (newPassword.length < AppConstants.minPasswordLength) {
      return Result.failure(
        Failure.validation(
          message: ValidationCode.passwordTooShort,
          field: ChangePasswordFields.next,
        ),
      );
    }

    if (newPassword == currentPassword) {
      return Result.failure(
        Failure.validation(
          message: ValidationCode.newPasswordSameAsCurrent,
          field: ChangePasswordFields.next,
        ),
      );
    }

    if (confirmPassword != newPassword) {
      return Result.failure(
        Failure.validation(
          message: ValidationCode.confirmPasswordMismatch,
          field: ChangePasswordFields.confirm,
        ),
      );
    }

    return const Result.success(Unit.instance);
  }
}

/// Validates, then sets the new password.
class ChangePasswordUseCase implements BaseUseCase<Unit, ChangePasswordParams> {
  final AuthRepository _repository;

  ChangePasswordUseCase(this._repository);

  @override
  FutureResult<Unit> call(ChangePasswordParams params) async {
    final validation = params.validate();
    if (validation.isFailure) {
      return Result.failure(validation.failureOrNull!);
    }

    return _repository.changePassword(
      currentPassword: params.currentPassword,
      newPassword: params.newPassword,
    );
  }
}
