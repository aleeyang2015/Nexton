import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/attendance_failure_x.dart';
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

  /// Whether the stat strip above the daily list has anything of its own to
  /// say.
  ///
  /// A login with no employee record fails the summary and the list the same
  /// way, and the page says so once, in the list. So once the list has
  /// answered "not linked", the strip is left out: while its own answer is
  /// still on the way (it will be the same one, and a placeholder above the
  /// message would only flicker), and when that answer arrives.
  bool get showsSummary {
    if (!_isNotLinked(records)) return true;
    final summaryPending = summary.isLoading && !summary.hasValue;
    return !(summaryPending || _isNotLinked(summary));
  }

  static bool _isNotLinked(AsyncValue<Object?> value) {
    final error = value.error;
    return value.hasError && error is Failure && error.isEmployeeNotLinked;
  }

  /// A month later than this one is in the future — nothing to show yet.
  bool get canGoNext {
    final now = DateTime.now();
    return month.isBefore(DateTime(now.year, now.month));
  }
}
