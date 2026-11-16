import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/network/paged_list.dart';
import '../../domain/entities/leave_request.dart';

part 'leave_history_state.freezed.dart';

/// Everything the history tab renders from: the active leave-type filter, the
/// viewed date range, the list loaded so far (it comes a page at a time, as
/// the user scrolls), and which requests currently have a cancel in flight.
@freezed
class LeaveHistoryState with _$LeaveHistoryState {
  const factory LeaveHistoryState({
    /// `null` means "all leave types".
    String? leaveTypeId,
    required DateTime from,
    required DateTime to,
    /// Loading, or failed, until the first page is in; from then on the rows
    /// so far, with the state of the next page inside the [PagedList].
    @Default(AsyncValue<PagedList<LeaveRequest>>.loading())
    AsyncValue<PagedList<LeaveRequest>> requests,
    @Default(<String>{}) Set<String> cancellingIds,
  }) = _LeaveHistoryState;
}
