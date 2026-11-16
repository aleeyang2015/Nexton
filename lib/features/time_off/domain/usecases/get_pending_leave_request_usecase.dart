import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/leave_request.dart';
import '../repositories/leave_repository.dart';

/// Finds the caller's leave request that is waiting for a decision, if there
/// is one (`GET /leave/requests/my?status=pending&limit=1`). The server
/// refuses a new request while one waits, so the form says so up front.
class GetPendingLeaveRequestUseCase implements NoParamsUseCase<LeaveRequest?> {
  final LeaveRepository _repository;

  GetPendingLeaveRequestUseCase(this._repository);

  @override
  FutureResult<LeaveRequest?> call() => _repository.pendingRequest();
}
