import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/network/paged_list.dart';
import '../../domain/entities/offsite_detail.dart';
import '../../domain/entities/time_correction_status.dart';

part 'offsite_approvals_state.freezed.dart';

/// What the approvals page's off-site tab renders from (#46), in #19's shape:
/// the scans waiting at the approver's step, then the ones they decided, one
/// of the two chips at a time. Each list is its own, a page at a time.
///
/// `my-approvals` answers each status from the caller's own step: `pending`
/// is what still waits on *this* approver (a request they cleared stays
/// pending overall while it sits with HR), `approved` / `rejected` a step
/// they decided. So each list is the server's, never filtered here.
@freezed
class OffsiteApprovalsState with _$OffsiteApprovalsState {
  const OffsiteApprovalsState._();

  const factory OffsiteApprovalsState({
    @Default(AsyncValue<PagedList<OffsiteRequestDetail>>.loading())
    AsyncValue<PagedList<OffsiteRequestDetail>> pending,
    @Default(AsyncValue<PagedList<OffsiteRequestDetail>>.loading())
    AsyncValue<PagedList<OffsiteRequestDetail>> decided,
    @Default(TimeCorrectionStatus.approved) TimeCorrectionStatus decidedFilter,

    /// Check-outs whose check-in was rejected or cancelled
    /// (`CHECKIN_NOT_APPROVED`): they can only be rejected, so Approve goes.
    @Default(<String>{}) Set<String> rejectOnlyIds,
  }) = _OffsiteApprovalsState;

  /// The two chips under "decided by me", in order.
  static const List<TimeCorrectionStatus> decidedStatuses = [
    TimeCorrectionStatus.approved,
    TimeCorrectionStatus.rejected,
  ];
}
