import '../../../../core/utils/base_repository.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/leave_approval.dart';
import '../../domain/entities/leave_history_query.dart';
import '../../domain/entities/leave_request.dart';
import '../../domain/entities/leave_request_draft.dart';
import '../../domain/entities/leave_summary.dart';
import '../../domain/repositories/leave_repository.dart';
import '../datasources/leave_remote_data_source.dart';

/// Wraps the remote source in [Result], via [BaseRepository.guard].
class LeaveRepositoryImpl extends BaseRepository implements LeaveRepository {
  final LeaveRemoteDataSource _remote;

  LeaveRepositoryImpl({required LeaveRemoteDataSource remote})
    : _remote = remote;

  @override
  FutureResult<List<LeaveRequest>> history(LeaveHistoryQuery query) =>
      guard(() => _remote.history(query));

  @override
  FutureResult<LeaveSummary> summary(int year) =>
      guard(() => _remote.summary(year));

  @override
  FutureResult<Unit> submit(LeaveRequestDraft draft) =>
      guard(() => _remote.submit(draft));

  @override
  FutureResult<List<LeaveApproval>> pendingApprovals() =>
      guard(() => _remote.pendingApprovals());

  @override
  FutureResult<List<LeaveApproval>> approvalHistory() =>
      guard(() => _remote.approvalHistory());

  @override
  FutureResult<Unit> decideApproval({
    required String requestId,
    required bool approve,
  }) => guard(
    () => _remote.decideApproval(requestId: requestId, approve: approve),
  );
}
