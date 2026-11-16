import '../../../../core/network/paged_list.dart';
import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/leave_history_query.dart';
import '../entities/leave_request.dart';
import '../repositories/leave_repository.dart';

/// What [GetLeaveHistoryUseCase] is asked: the filter, and where to go on
/// from (null for the first page).
typedef LeaveHistoryPageParams = ({LeaveHistoryQuery query, String? cursor});

/// Loads one page of the history tab's list for a [LeaveHistoryQuery]
/// (`GET /leave/requests/my`).
class GetLeaveHistoryUseCase
    implements BaseUseCase<CursorPage<LeaveRequest>, LeaveHistoryPageParams> {
  final LeaveRepository _repository;

  GetLeaveHistoryUseCase(this._repository);

  @override
  FutureResult<CursorPage<LeaveRequest>> call(LeaveHistoryPageParams params) =>
      _repository.myRequests(params.query, cursor: params.cursor);
}
