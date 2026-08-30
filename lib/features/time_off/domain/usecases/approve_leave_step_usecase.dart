import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/leave_request.dart';
import '../repositories/leave_repository.dart';

/// Approves the current step of a request (`PUT /leave/requests/:id/approve`).
///
/// [stepId] is the id of the step currently `pending` (from `steps[]`); the
/// backend answers `409 STEP_CHANGED` if it has moved on.
class ApproveLeaveStepUseCase
    implements
        BaseUseCase<LeaveRequest, ({String id, String? stepId, String? note})> {
  final LeaveRepository _repository;

  ApproveLeaveStepUseCase(this._repository);

  @override
  FutureResult<LeaveRequest> call(
    ({String id, String? stepId, String? note}) p,
  ) => _repository.approve(id: p.id, stepId: p.stepId, note: p.note);
}
