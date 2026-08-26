import '../../../../core/utils/result.dart';
import '../entities/leave_approval.dart';
import '../entities/leave_history_query.dart';
import '../entities/leave_request.dart';
import '../entities/leave_request_draft.dart';
import '../entities/leave_summary.dart';

/// Contract the presentation layer depends on. The implementation lives in
/// data/repositories.
abstract class LeaveRepository {
  /// The history tab's list, filtered by [LeaveHistoryQuery].
  FutureResult<List<LeaveRequest>> history(LeaveHistoryQuery query);

  /// The annual summary tab's entitlement/used/remaining rollup for [year].
  FutureResult<LeaveSummary> summary(int year);

  /// Submits the request-leave form.
  FutureResult<Unit> submit(LeaveRequestDraft draft);

  /// The approvals tab's "needs your decision" list — subordinates' leave
  /// requests still awaiting a manager decision.
  FutureResult<List<LeaveApproval>> pendingApprovals();

  /// The approvals tab's "already decided" list.
  FutureResult<List<LeaveApproval>> approvalHistory();

  /// Approves or rejects one subordinate's request.
  FutureResult<Unit> decideApproval({
    required String requestId,
    required bool approve,
  });
}
