import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/validation_codes.dart';
import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

/// Field names a [ValidationFailure] can point at, so the UI knows
/// which input to mark without matching on message strings.
class LoginFields {
  LoginFields._();

  static const String email = 'email';
  static const String password = 'password';
}

/// Credentials plus the rules they must satisfy
class LoginParams extends BaseParams {
  final String email;
  final String password;

  LoginParams({required this.email, required this.password});

  @override
  Result<Unit> validate() {
    final trimmedEmail = email.trim();

    if (trimmedEmail.isEmpty) {
      return Result.failure(
        Failure.validation(
          message: ValidationCode.emailRequired,
          field: LoginFields.email,
        ),
      );
    }

    if (!RegExp(AppConstants.emailRegex).hasMatch(trimmedEmail)) {
      return Result.failure(
        Failure.validation(
          message: ValidationCode.emailInvalid,
          field: LoginFields.email,
        ),
      );
    }

    if (password.isEmpty) {
      return Result.failure(
        Failure.validation(
          message: ValidationCode.passwordRequired,
          field: LoginFields.password,
        ),
      );
    }

    if (password.length < AppConstants.minPasswordLength) {
      return Result.failure(
        Failure.validation(
          message: ValidationCode.passwordTooShort,
          field: LoginFields.password,
        ),
      );
    }

    return const Result.success(Unit.instance);
  }
}

/// Validates credentials, then signs the user in.
///
/// The email is trimmed **and lower-cased** before it goes to the backend, so
/// the same account can't be created twice by capitalisation.
class LoginUseCase implements BaseUseCase<AuthSession, LoginParams> {
  final AuthRepository _repository;

  LoginUseCase(this._repository);

  @override
  FutureResult<AuthSession> call(LoginParams params) async {
    final validation = params.validate();
    if (validation.isFailure) {
      return Result.failure(validation.failureOrNull!);
    }

    return _repository.login(
      email: params.email.trim().toLowerCase(),
      password: params.password,
    );
  }
}
