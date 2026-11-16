import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/result.dart';
import '../../data/datasources/leave_error_code.dart';
import '../../domain/entities/leave_history_query.dart';
import '../../domain/entities/leave_request.dart';
import '../../time_off_providers.dart';
import 'leave_balances_notifier.dart';
import 'leave_history_state.dart';
import 'leave_pending_request_notifier.dart';

/// Owns the history tab's filter, date range and fetched list, plus the
/// cancel action reachable from the detail page. The tab renders what comes
/// back and forwards taps here; it holds no fetching logic of its own.
class LeaveHistoryNotifier extends AutoDisposeNotifier<LeaveHistoryState> {
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

  void filterByLeaveType(String? leaveTypeId) {
    state = state.copyWith(leaveTypeId: leaveTypeId);
    _load();
  }

  void setRange(DateTime from, DateTime to) {
    state = state.copyWith(from: from, to: to);
    _load();
  }

  /// Re-runs the current filter's fetch, e.g. after the user retries a
  /// failed load.
  void retry() => _load();

  /// Cancels [requestId] (`PUT /leave/requests/:id/cancel`) and returns the
  /// server's answer, so the page can say why it was refused.
  ///
  /// On success the list and the balances refetch. They also refetch when
  /// the refusal means the owner's copy is out of date (the request changed,
  /// can no longer be cancelled, or is gone): the list then shows it as it
  /// now is.
  Future<Result<LeaveRequest>> cancel(String requestId) async {
    state = state.copyWith(cancellingIds: {...state.cancellingIds, requestId});

    final result = await ref.read(cancelLeaveRequestUseCaseProvider)(requestId);
    if (_disposed) return result;

    // The request stays marked as cancelling until the list is back, so its
    // Cancel button cannot be tapped a second time while the page waits.
    final stale = result.fold(LeaveErrorCode.isStaleForOwner, (_) => false);
    if (result.isSuccess || stale) {
      ref.invalidate(leaveBalancesNotifierProvider);
      ref.invalidate(leavePendingRequestNotifierProvider);
      await _load();
      if (_disposed) return result;
    }

    state = state.copyWith(
      cancellingIds: {...state.cancellingIds}..remove(requestId),
    );
    return result;
  }

  Future<void> _load() async {
    final query = LeaveHistoryQuery(
      leaveTypeId: state.leaveTypeId,
      from: state.from,
      to: state.to,
    );
    state = state.copyWith(requests: const AsyncValue.loading());

    final result = await ref.read(getLeaveHistoryUseCaseProvider)(query);
    if (_disposed ||
        state.leaveTypeId != query.leaveTypeId ||
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
    NotifierProvider.autoDispose<LeaveHistoryNotifier, LeaveHistoryState>(
      LeaveHistoryNotifier.new,
    );
