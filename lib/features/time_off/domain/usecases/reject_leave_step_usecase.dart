import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/leave_request.dart';
import '../repositories/leave_repository.dart';

/// Rejects a request at the current step (`PUT /leave/requests/:id/reject`).
/// [reason] is required by the backend; a rejection ends the whole request.
class RejectLeaveStepUseCase
    implements
        BaseUseCase<
          LeaveRequest,
          ({String id, String reason, String? stepId, String? note})
        > {
  final LeaveRepository _repository;

  RejectLeaveStepUseCase(this._repository);

  @override
  FutureResult<LeaveRequest> call(
    ({String id, String reason, String? stepId, String? note}) p,
  ) => _repository.reject(
    id: p.id,
    reason: p.reason,
    stepId: p.stepId,
    note: p.note,
  );
}
