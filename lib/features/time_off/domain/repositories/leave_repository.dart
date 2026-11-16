import '../../../../core/network/paged_list.dart';
import '../../../../core/utils/result.dart';
import '../entities/company_days_off.dart';
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

  /// `GET /core_hr/rest-days` — the company's days off, every page of them.
  FutureResult<CompanyDaysOff> companyDaysOff();

  /// `GET /leave/balances/my` — the per-type quota rollup for [year].
  FutureResult<List<LeaveBalance>> balances(int year);

  /// `GET /leave/requests/my` — one page of the history tab's list. [cursor]
  /// is the page before's `nextCursor`; leave it out for the first page.
  FutureResult<CursorPage<LeaveRequest>> myRequests(
    LeaveHistoryQuery query, {
    String? cursor,
  });

  /// `GET /leave/requests/my?status=pending&limit=1` — the caller's request
  /// that is waiting for a decision, or null when there is none. While one
  /// waits, the server refuses a new request.
  FutureResult<LeaveRequest?> pendingRequest();

  /// `GET /leave/requests/:id` — the detail page.
  FutureResult<LeaveRequest> requestDetail(String id);

  /// `POST /leave/requests` — submits the request-leave form.
  FutureResult<LeaveRequest> submit(LeaveRequestDraft draft);

  /// `PUT /leave/requests/:id` — edits a still-pending request.
  FutureResult<LeaveRequest> update(String id, LeaveRequestDraft draft);

  /// `PUT /leave/requests/:id/cancel` — cancels a pending/approved request.
  FutureResult<LeaveRequest> cancel(String id);

  /// `GET /leave/requests/my-approvals` — one page of an approvals list,
  /// scoped to the caller's role. [status] filters by **the caller's own
  /// step**, not the request's status: `pending` is what waits for the
  /// caller now, `approved` / `rejected` what the caller approved or
  /// rejected, whatever happened to the request later. [cursor] is the page
  /// before's `nextCursor`.
  FutureResult<CursorPage<LeaveRequest>> myApprovals({
    LeaveStatus? status,
    String? cursor,
  });

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
