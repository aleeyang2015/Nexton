import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../repositories/offsite_repository.dart';

/// Withdraws one of the employee's own pending off-site scan requests, by id
/// (§9) — the action behind the history card's "cancel" button.
class CancelOffsiteRequestUseCase implements BaseUseCase<Unit, String> {
  final OffsiteRepository _repository;

  CancelOffsiteRequestUseCase(this._repository);

  @override
  FutureResult<Unit> call(String id) => _repository.cancel(id);
}
