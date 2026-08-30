import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/leave_request.dart';

part 'leave_approvals_state.freezed.dart';

/// How a decision (`approve` / `reject`) turned out.
enum LeaveDecisionOutcome {
  success,

  /// `409 STEP_CHANGED` — someone else moved the request on. The lists have
  /// been refetched; the approver should look again.
  stepChanged,

  failed,
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
