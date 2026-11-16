import '../../../../core/network/paged_list.dart';
import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/leave_request.dart';
import '../entities/leave_status.dart';
import '../repositories/leave_repository.dart';

/// What [GetLeaveApprovalsUseCase] is asked: which of the caller's lists
/// (null for all of them), and where to go on from (null for the first
/// page).
typedef LeaveApprovalsPageParams = ({LeaveStatus? status, String? cursor});

/// Loads one page of an approvals list
/// (`GET /leave/requests/my-approvals`).
///
/// `status` filters by **the caller's own step**, not the request's status:
/// `pending` is what waits for the caller now; `approved` and `rejected` are
/// the requests the caller approved or rejected, whatever happened to them
/// later (a later step, a cancel).
class GetLeaveApprovalsUseCase
    implements
        BaseUseCase<CursorPage<LeaveRequest>, LeaveApprovalsPageParams> {
  final LeaveRepository _repository;

  GetLeaveApprovalsUseCase(this._repository);

  @override
  FutureResult<CursorPage<LeaveRequest>> call(
    LeaveApprovalsPageParams params,
  ) => _repository.myApprovals(status: params.status, cursor: params.cursor);
}
