import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/leave_request.dart';
import '../entities/leave_request_draft.dart';
import '../repositories/leave_repository.dart';

/// Submits the request-leave form (`POST /leave/requests`).
class SubmitLeaveRequestUseCase
    implements BaseUseCase<LeaveRequest, LeaveRequestDraft> {
  final LeaveRepository _repository;

  SubmitLeaveRequestUseCase(this._repository);

  @override
  FutureResult<LeaveRequest> call(LeaveRequestDraft draft) =>
      _repository.submit(draft);
}
