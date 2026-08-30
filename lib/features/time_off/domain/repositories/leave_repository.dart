import '../../../../core/utils/result.dart';
import '../entities/leave_balance.dart';
import '../entities/leave_history_query.dart';
import '../entities/leave_request.dart';
import '../entities/leave_request_draft.dart';
import '../entities/leave_status.dart';
import '../entities/leave_type.dart';

/// Contract the presentation layer depends on. The implementation lives in
/// data/repositories and talks to `/api/v1/core_hr/leave/*`
/// (leave-request-flutter.md).
abstract class LeaveRepository {
  /// `GET /leave/types` — the dropdown of leave categories.
  FutureResult<List<LeaveType>> leaveTypes();

  /// `GET /leave/balances/my` — the per-type quota rollup for [year].
  FutureResult<List<LeaveBalance>> balances(int year);

  /// `GET /leave/requests/my` — the history tab's list.
  FutureResult<List<LeaveRequest>> myRequests(LeaveHistoryQuery query);

  /// `GET /leave/requests/:id` — the detail page.
  FutureResult<LeaveRequest> requestDetail(String id);

  /// `POST /leave/requests` — submits the request-leave form.
  FutureResult<LeaveRequest> submit(LeaveRequestDraft draft);

  /// `PUT /leave/requests/:id` — edits a still-pending request.
  FutureResult<LeaveRequest> update(String id, LeaveRequestDraft draft);

  /// `PUT /leave/requests/:id/cancel` — cancels a pending/approved request.
  FutureResult<LeaveRequest> cancel(String id);

  /// `GET /leave/requests/my-approvals` — the approvals tab's list, scoped to
  /// the caller's role. [status] filters by the whole request's status.
  FutureResult<List<LeaveRequest>> myApprovals({LeaveStatus? status});

  /// `PUT /leave/requests/:id/approve` — approves the current step.
  FutureResult<LeaveRequest> approve({
    required String id,
    String? stepId,
    String? note,
  });

  /// `PUT /leave/requests/:id/reject` — rejects at the current step; [reason]
  /// is required by the backend.
  FutureResult<LeaveRequest> reject({
    required String id,
    required String reason,
    String? stepId,
    String? note,
  });
}
