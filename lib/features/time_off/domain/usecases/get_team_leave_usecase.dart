import '../../../../core/network/paged_list.dart';
import '../../../../core/utils/result.dart';
import '../entities/leave_request.dart';
import '../entities/leave_status.dart';
import '../repositories/leave_repository.dart';

/// One page of the head's team's leave requests, read-only (#50).
class GetTeamLeaveUseCase {
  final LeaveRepository _repository;

  GetTeamLeaveUseCase(this._repository);

  FutureResult<CursorPage<LeaveRequest>> call({
    LeaveStatus? status,
    String? cursor,
  }) => _repository.teamRequests(status: status, cursor: cursor);
}
