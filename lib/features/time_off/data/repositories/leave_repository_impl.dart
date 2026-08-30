import '../../../../core/utils/base_repository.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/leave_balance.dart';
import '../../domain/entities/leave_history_query.dart';
import '../../domain/entities/leave_request.dart';
import '../../domain/entities/leave_request_draft.dart';
import '../../domain/entities/leave_status.dart';
import '../../domain/entities/leave_type.dart';
import '../../domain/repositories/leave_repository.dart';
import '../datasources/leave_remote_data_source.dart';

/// Wraps the remote source in [Result], via [BaseRepository.guard].
class LeaveRepositoryImpl extends BaseRepository implements LeaveRepository {
  final LeaveRemoteDataSource _remote;

  LeaveRepositoryImpl({required LeaveRemoteDataSource remote})
    : _remote = remote;

  @override
  FutureResult<List<LeaveType>> leaveTypes() => guard(_remote.types);

  @override
  FutureResult<List<LeaveBalance>> balances(int year) =>
      guard(() => _remote.balances(year));

  @override
  FutureResult<List<LeaveRequest>> myRequests(LeaveHistoryQuery query) =>
      guard(() => _remote.myRequests(query));

  @override
  FutureResult<LeaveRequest> requestDetail(String id) =>
      guard(() => _remote.requestDetail(id));

  @override
  FutureResult<LeaveRequest> submit(LeaveRequestDraft draft) =>
      guard(() => _remote.submit(draft));

  @override
  FutureResult<LeaveRequest> update(String id, LeaveRequestDraft draft) =>
      guard(() => _remote.update(id, draft));

  @override
  FutureResult<LeaveRequest> cancel(String id) =>
      guard(() => _remote.cancel(id));

  @override
  FutureResult<List<LeaveRequest>> myApprovals({LeaveStatus? status}) =>
      guard(() => _remote.myApprovals(status: status));

  @override
  FutureResult<LeaveRequest> approve({
    required String id,
    String? stepId,
    String? note,
  }) => guard(() => _remote.approve(id: id, stepId: stepId, note: note));

  @override
  FutureResult<LeaveRequest> reject({
    required String id,
    required String reason,
    String? stepId,
    String? note,
  }) => guard(
    () => _remote.reject(id: id, reason: reason, stepId: stepId, note: note),
  );
}
