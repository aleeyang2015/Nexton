import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/leave_request.dart';
import '../entities/leave_status.dart';
import '../repositories/leave_repository.dart';

/// Loads the approvals tab's list (`GET /leave/requests/my-approvals`),
/// optionally filtered by the whole request's [status] (`null` = every
/// status).
class GetLeaveApprovalsUseCase
    implements BaseUseCase<List<LeaveRequest>, LeaveStatus?> {
  final LeaveRepository _repository;

  GetLeaveApprovalsUseCase(this._repository);

  @override
  FutureResult<List<LeaveRequest>> call(LeaveStatus? status) =>
      _repository.myApprovals(status: status);
}
