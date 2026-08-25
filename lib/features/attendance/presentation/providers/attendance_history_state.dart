import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/attendance_day.dart';
import '../../domain/entities/attendance_summary.dart';

part 'attendance_history_state.freezed.dart';

/// Everything the history page renders from: the month being viewed, its
/// records and stat summary, and which rows are expanded.
@freezed
class AttendanceHistoryState with _$AttendanceHistoryState {
  const AttendanceHistoryState._();

  const factory AttendanceHistoryState({
    /// The 1st of the viewed month, local time.
    required DateTime month,
    @Default(AsyncValue<List<AttendanceDay>>.loading())
    AsyncValue<List<AttendanceDay>> records,
    @Default(AsyncValue<AttendanceSummary>.loading())
    AsyncValue<AttendanceSummary> summary,
    @Default(<int>{}) Set<int> expandedIndexes,
  }) = _AttendanceHistoryState;

  /// A month later than this one is in the future — nothing to show yet.
  bool get canGoNext {
    final now = DateTime.now();
    return month.isBefore(DateTime(now.year, now.month));
  }
}
