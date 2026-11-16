import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/leave_request.dart';

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
  /// [LeaveDecisionKind.failed]. Null on success, and for a decision whose
  /// screen was closed before the answer came.
  final Failure? failure;

  const LeaveDecisionOutcome._(this.kind, this.failure);

  static const success = LeaveDecisionOutcome._(
    LeaveDecisionKind.success,
    null,
  );

  const LeaveDecisionOutcome.reloaded(Failure failure)
    : this._(LeaveDecisionKind.reloaded, failure);

  const LeaveDecisionOutcome.failed([Failure? failure])
    : this._(LeaveDecisionKind.failed, failure);
}

/// Everything the approvals tab renders from: the pending list, the
/// decided-history list, and which requests currently have a decision in
/// flight (so their buttons can disable individually).
@freezed
class LeaveApprovalsState with _$LeaveApprovalsState {
  const factory LeaveApprovalsState({
    @Default(AsyncValue<List<LeaveRequest>>.loading())
    AsyncValue<List<LeaveRequest>> pending,
    @Default(AsyncValue<List<LeaveRequest>>.loading())
    AsyncValue<List<LeaveRequest>> history,
    @Default(<String>{}) Set<String> decidingIds,
  }) = _LeaveApprovalsState;
}
