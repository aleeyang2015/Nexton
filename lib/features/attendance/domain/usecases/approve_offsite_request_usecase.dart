import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../repositories/offsite_repository.dart';

/// Approves the current step of a pending off-site scan request.
///
/// [stepId] is the step the approver saw pending; sending it lets the backend
/// refuse (`STEP_CHANGED`) rather than apply the decision to a step someone
/// else has meanwhile moved past.
class ApproveOffsiteRequestUseCase
    implements BaseUseCase<Unit, ({String id, String? stepId})> {
  final OffsiteRepository _repository;

  ApproveOffsiteRequestUseCase(this._repository);

  @override
  FutureResult<Unit> call(({String id, String? stepId}) p) =>
      _repository.approve(p.id, stepId: p.stepId);
}
