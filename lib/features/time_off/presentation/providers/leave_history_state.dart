import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/leave_category.dart';
import '../../domain/entities/leave_request.dart';

part 'leave_history_state.freezed.dart';

/// Everything the history tab renders from: the active filter, the viewed
/// date range and the fetched list.
@freezed
class LeaveHistoryState with _$LeaveHistoryState {
  const factory LeaveHistoryState({
    /// `null` means "all categories".
    LeaveCategory? category,
    required DateTime from,
    required DateTime to,
    @Default(AsyncValue<List<LeaveRequest>>.loading())
    AsyncValue<List<LeaveRequest>> requests,
  }) = _LeaveHistoryState;
}
