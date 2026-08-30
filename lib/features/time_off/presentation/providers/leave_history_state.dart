import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/leave_request.dart';

part 'leave_history_state.freezed.dart';

/// Everything the history tab renders from: the active leave-type filter, the
/// viewed date range, the fetched list, and which requests currently have a
/// cancel in flight.
@freezed
class LeaveHistoryState with _$LeaveHistoryState {
  const factory LeaveHistoryState({
    /// `null` means "all leave types".
    String? leaveTypeId,
    required DateTime from,
    required DateTime to,
    @Default(AsyncValue<List<LeaveRequest>>.loading())
    AsyncValue<List<LeaveRequest>> requests,
    @Default(<String>{}) Set<String> cancellingIds,
  }) = _LeaveHistoryState;
}
