import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/leave_history_query.dart';
import '../entities/leave_request.dart';
import '../repositories/leave_repository.dart';

/// Loads the history tab's list for a [LeaveHistoryQuery]
/// (`GET /leave/requests/my`).
class GetLeaveHistoryUseCase
    implements BaseUseCase<List<LeaveRequest>, LeaveHistoryQuery> {
  final LeaveRepository _repository;

  GetLeaveHistoryUseCase(this._repository);

  @override
  FutureResult<List<LeaveRequest>> call(LeaveHistoryQuery query) =>
      _repository.myRequests(query);
}
