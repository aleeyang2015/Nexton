import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/user.dart';
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
          message: 'ກະລຸນາປ້ອນອີເມວ',
          field: LoginFields.email,
        ),
      );
    }

    if (!RegExp(AppConstants.emailRegex).hasMatch(trimmedEmail)) {
      return Result.failure(
        Failure.validation(
          message: 'ຮູບແບບອີເມວບໍ່ຖືກຕ້ອງ',
          field: LoginFields.email,
        ),
      );
    }

    if (password.isEmpty) {
      return Result.failure(
        Failure.validation(
          message: 'ກະລຸນາປ້ອນລະຫັດຜ່ານ',
          field: LoginFields.password,
        ),
      );
    }

    if (password.length < AppConstants.minPasswordLength) {
      return Result.failure(
        Failure.validation(
          message:
              'ລະຫັດຜ່ານຕ້ອງມີຢ່າງໜ້ອຍ ${AppConstants.minPasswordLength} ຕົວອັກສອນ',
          field: LoginFields.password,
        ),
      );
    }

    return const Result.success(Unit.instance);
  }
}

/// Validates credentials, then signs the user in
class LoginUseCase implements BaseUseCase<User, LoginParams> {
  final AuthRepository _repository;

  LoginUseCase(this._repository);

  @override
  FutureResult<User> call(LoginParams params) async {
    final validation = params.validate();
    if (validation.isFailure) {
      return Result.failure(validation.failureOrNull!);
    }

    return _repository.login(
      email: params.email.trim(),
      password: params.password,
    );
  }
}
