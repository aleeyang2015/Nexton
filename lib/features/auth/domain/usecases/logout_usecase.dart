import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../repositories/auth_repository.dart';

/// Ends the current session
class LogoutUseCase implements NoParamsUseCase<Unit> {
  final AuthRepository _repository;

  LogoutUseCase(this._repository);

  @override
  FutureResult<Unit> call() => _repository.logout();
}
