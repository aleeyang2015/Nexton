import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/network/paged_list.dart';
import '../../domain/entities/leave_request.dart';
import '../../domain/entities/leave_status.dart';

part 'leave_approvals_state.freezed.dart';

/// The three ways a decision (`approve` / `reject`) can turn out.
enum LeaveDecisionKind {
  success,

  /// The server refused because what the approver was looking at is no
  /// longer so: someone else moved the request on, its days changed, it was
  /// decided or cancelled, it is not this approver's step, or it is gone.
  /// Both lists have been refetched; the approver should look again.
  reloaded,

  /// Anything else. The lists are as they were.
  failed,
}

/// How a decision turned out, with the server's refusal when there was one,
/// so the tab can say why.
class LeaveDecisionOutcome {
  final LeaveDecisionKind kind;

  /// The refusal behind [LeaveDecisionKind.reloaded] or
  /// [LeaveDecisionKind.failed]. Null on success.
  final Failure? failure;

  /// True when the approvals screen was closed before the answer came:
  /// there is nobody to tell.
  final bool abandoned;

  const LeaveDecisionOutcome._(
    this.kind,
    this.failure, {
    this.abandoned = false,
  });

  /// The screen was closed before the answer came.
  static const gone = LeaveDecisionOutcome._(
    LeaveDecisionKind.failed,
    null,
    abandoned: true,
  );

  static const success = LeaveDecisionOutcome._(
    LeaveDecisionKind.success,
    null,
  );

  const LeaveDecisionOutcome.reloaded(Failure failure)
    : this._(LeaveDecisionKind.reloaded, failure);

  const LeaveDecisionOutcome.failed([Failure? failure])
    : this._(LeaveDecisionKind.failed, failure);
}

/// Which of the approver's own decisions the "decided" list shows. Two
/// server lists, not one mixed list: a list that comes a page at a time
/// cannot be filtered on the phone without gaps.
enum LeaveDecidedFilter {
  approved(LeaveStatus.approved),
  rejected(LeaveStatus.rejected);

  const LeaveDecidedFilter(this.status);

  /// The `status` the approvals endpoint is asked with.
  final LeaveStatus status;
}

/// Everything the approvals tab renders from: the pending list, the
/// decided-history list, and which requests currently have a decision in
/// flight (so their buttons can disable individually).
@freezed
class LeaveApprovalsState with _$LeaveApprovalsState {
  const factory LeaveApprovalsState({
    /// What waits for the signed-in approver now, a page at a time.
    @Default(AsyncValue<PagedList<LeaveRequest>>.loading())
    AsyncValue<PagedList<LeaveRequest>> pending,

    /// What the approver approved, or rejected ([decidedFilter]), a page at
    /// a time, whatever became of the request afterwards.
    @Default(AsyncValue<PagedList<LeaveRequest>>.loading())
    AsyncValue<PagedList<LeaveRequest>> decided,
    @Default(LeaveDecidedFilter.approved) LeaveDecidedFilter decidedFilter,

    /// The signed-in user's own employee id, to tell their own request from
    /// someone else's. Null means unknown; then no card counts as their own.
    String? ownEmployeeId,
    @Default(<String>{}) Set<String> decidingIds,
  }) = _LeaveApprovalsState;

  const LeaveApprovalsState._();

  /// True when [request] was asked for by the signed-in user. Nobody decides
  /// their own request: the server refuses it.
  bool isOwn(LeaveRequest request) =>
      ownEmployeeId != null && request.employeeId == ownEmployeeId;
}
