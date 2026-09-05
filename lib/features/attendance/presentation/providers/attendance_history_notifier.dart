import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/result.dart';
import '../../attendance_providers.dart';
import '../../domain/entities/date_range.dart';
import 'attendance_history_state.dart';

/// Owns the history page's month, its records and summary, and which rows
/// are expanded. The page renders what comes back and forwards taps here;
/// it holds no fetching logic of its own.
class AttendanceHistoryNotifier
    extends AutoDisposeNotifier<AttendanceHistoryState> {
  bool _disposed = false;

  @override
  AttendanceHistoryState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);

    final now = DateTime.now();
    final month = DateTime(now.year, now.month);
    Future.microtask(() => _load(month));

    return AttendanceHistoryState(month: month);
  }

  void previousMonth() {
    final month = state.month;
    _load(DateTime(month.year, month.month - 1));
  }

  void nextMonth() {
    if (!state.canGoNext) return;
    final month = state.month;
    _load(DateTime(month.year, month.month + 1));
  }

  /// Re-runs the current month's fetch, e.g. after the user retries a
  /// failed load.
  void retry() => _load(state.month);

  void toggleExpanded(int index) {
    final expanded = Set<int>.from(state.expandedIndexes);
    if (!expanded.remove(index)) expanded.add(index);
    state = state.copyWith(expandedIndexes: expanded);
  }

  Future<void> _load(DateTime month) async {
    // A fresh month resets everything, including which rows were expanded —
    // those indexes belong to the previous month's list.
    state = AttendanceHistoryState(month: month);
    final range = DateRange.month(month);

    final recordsFuture = ref.read(getMonthlyRecordsUseCaseProvider)(range);
    final summaryFuture = ref.read(getMonthlySummaryUseCaseProvider)(range);

    final recordsResult = await recordsFuture;
    if (_disposed || state.month != month) return;
    state = state.copyWith(records: _toAsync(recordsResult));

    final summaryResult = await summaryFuture;
    if (_disposed || state.month != month) return;
    state = state.copyWith(summary: _toAsync(summaryResult));
  }

  AsyncValue<T> _toAsync<T>(Result<T> result) => result.fold(
    (failure) => AsyncValue<T>.error(failure, StackTrace.current),
    (value) => AsyncValue<T>.data(value),
  );
}

final attendanceHistoryNotifierProvider =
    NotifierProvider.autoDispose<
      AttendanceHistoryNotifier,
      AttendanceHistoryState
    >(AttendanceHistoryNotifier.new);
