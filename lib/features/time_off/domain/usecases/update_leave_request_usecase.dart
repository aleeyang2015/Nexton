import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/leave_request.dart';
import '../entities/leave_request_draft.dart';
import '../repositories/leave_repository.dart';

/// Edits a still-pending request (`PUT /leave/requests/:id`).
class UpdateLeaveRequestUseCase
    implements
        BaseUseCase<LeaveRequest, ({String id, LeaveRequestDraft draft})> {
  final LeaveRepository _repository;

  UpdateLeaveRequestUseCase(this._repository);

  @override
  FutureResult<LeaveRequest> call(({String id, LeaveRequestDraft draft}) p) =>
      _repository.update(p.id, p.draft);
}
