import '../../../../core/utils/result.dart';
import '../repositories/auth_repository.dart';

/// Ends the current session. [endSession]: the server ends this phone's
/// sign-in too (#56): the user signed out, and the tokens still work.
class LogoutUseCase {
  final AuthRepository _repository;

  LogoutUseCase(this._repository);

  FutureResult<Unit> call({bool endSession = false}) =>
      _repository.logout(endSession: endSession);
}
