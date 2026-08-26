import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/result.dart';
import '../../domain/entities/leave_category.dart';
import '../../domain/entities/leave_history_query.dart';
import '../../domain/entities/leave_request.dart';
import '../../time_off_providers.dart';
import 'leave_history_state.dart';

/// Owns the history tab's filter, date range and fetched list. The tab
/// renders what comes back and forwards taps here; it holds no fetching
/// logic of its own.
class LeaveHistoryNotifier extends Notifier<LeaveHistoryState> {
  bool _disposed = false;

  @override
  LeaveHistoryState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);

    final now = DateTime.now();
    final from = DateTime(now.year, now.month);
    final to = DateTime(now.year, now.month + 1, 0);
    Future.microtask(_load);

    return LeaveHistoryState(from: from, to: to);
  }

  void filterByCategory(LeaveCategory? category) {
    state = state.copyWith(category: category);
    _load();
  }

  void setRange(DateTime from, DateTime to) {
    state = state.copyWith(from: from, to: to);
    _load();
  }

  /// Re-runs the current filter's fetch, e.g. after the user retries a
  /// failed load.
  void retry() => _load();

  Future<void> _load() async {
    final query = LeaveHistoryQuery(
      category: state.category,
      from: state.from,
      to: state.to,
    );
    state = state.copyWith(requests: const AsyncValue.loading());

    final result = await ref.read(getLeaveHistoryUseCaseProvider)(query);
    if (_disposed ||
        state.category != query.category ||
        state.from != query.from ||
        state.to != query.to) {
      return;
    }
    state = state.copyWith(requests: _toAsync(result));
  }

  AsyncValue<List<LeaveRequest>> _toAsync(Result<List<LeaveRequest>> result) =>
      result.fold(
        (failure) => AsyncValue.error(failure, StackTrace.current),
        (data) => AsyncValue.data(data),
      );
}

final leaveHistoryNotifierProvider =
    NotifierProvider<LeaveHistoryNotifier, LeaveHistoryState>(
      LeaveHistoryNotifier.new,
    );
