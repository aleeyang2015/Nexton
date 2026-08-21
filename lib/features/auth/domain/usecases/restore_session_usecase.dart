import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

/// Cold start: turn whatever tokens are on disk into a session.
class RestoreSessionUseCase implements NoParamsUseCase<AuthSession> {
  final AuthRepository _repository;

  RestoreSessionUseCase(this._repository);

  @override
  FutureResult<AuthSession> call() => _repository.restoreSession();
}
