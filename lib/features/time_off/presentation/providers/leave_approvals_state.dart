import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/leave_approval.dart';

part 'leave_approvals_state.freezed.dart';

/// Everything the approvals tab renders from: the pending list, the
/// decided-history list, and which requests currently have a decision
/// in flight (so their buttons can disable individually).
@freezed
class LeaveApprovalsState with _$LeaveApprovalsState {
  const factory LeaveApprovalsState({
    @Default(AsyncValue<List<LeaveApproval>>.loading())
    AsyncValue<List<LeaveApproval>> pending,
    @Default(AsyncValue<List<LeaveApproval>>.loading())
    AsyncValue<List<LeaveApproval>> history,
    @Default(<String>{}) Set<String> decidingIds,
  }) = _LeaveApprovalsState;
}
