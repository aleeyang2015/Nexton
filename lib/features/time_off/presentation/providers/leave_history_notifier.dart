import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/network/paged_list.dart';
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

  /// Re-runs the current filter's fetch from its first page, e.g. after the
  /// user retries a failed load.
  void retry() => _load();

  /// Fetches the page after the rows already shown and adds it under them.
  /// Called as the user nears the end of the list.
  ///
  /// Does nothing when there is no next page, while one is on its way (one
  /// page at a time), or after one failed: that waits for [retryLoadMore].
  /// An answer for a filter or range the user has since left, or for a list
  /// that has been reloaded meanwhile, is dropped.
  Future<void> loadMore() async {
    final list = state.requests.valueOrNull;
    if (list == null || state.requests.isLoading || !list.canLoadMore) return;

    final query = _query();
    final loadedAs = _loads;
    state = state.copyWith(
      requests: AsyncValue.data(list.startLoadingMore()),
    );

    final result = await ref.read(getLeaveHistoryUseCaseProvider)((
      query: query,
      cursor: list.nextCursor,
    ));
    if (_disposed || loadedAs != _loads || query != _query()) return;

    state = state.copyWith(
      requests: AsyncValue.data(
        result.fold(list.failLoadingMore, list.append),
      ),
    );
  }

  /// The Retry under the rows, after a next page failed.
  ///
  /// A page the server refused (`400`: the cursor is no longer good) cannot
  /// be asked for again, so the list starts over from its first page.
  /// Anything else (no signal, a server error) asks for the same page.
  Future<void> retryLoadMore() async {
    final list = state.requests.valueOrNull;
    final error = list?.loadMoreError;
    if (list == null || error == null) return;

    if (error is ValidationFailure) return _load();

    state = state.copyWith(
      requests: AsyncValue.data(
        PagedList(
          items: list.items,
          nextCursor: list.nextCursor,
          hasMore: list.hasMore,
        ),
      ),
    );
    return loadMore();
  }

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

  /// How many times the list has been loaded from its first page. A page
  /// asked for before the latest of them belongs to a list that is gone.
  int _loads = 0;

  LeaveHistoryQuery _query() => LeaveHistoryQuery(
    leaveTypeId: state.leaveTypeId,
    from: state.from,
    to: state.to,
  );

  /// Loads the first page for the current filter and range, replacing
  /// whatever was shown.
  Future<void> _load() async {
    final query = _query();
    final loadedAs = ++_loads;
    state = state.copyWith(requests: const AsyncValue.loading());

    final result = await ref.read(getLeaveHistoryUseCaseProvider)((
      query: query,
      cursor: null,
    ));
    if (_disposed || loadedAs != _loads || query != _query()) return;

    state = state.copyWith(
      requests: result.fold(
        (failure) => AsyncValue.error(failure, StackTrace.current),
        (page) => AsyncValue.data(PagedList.first(page)),
      ),
    );
  }
}

final leaveHistoryNotifierProvider =
    NotifierProvider.autoDispose<LeaveHistoryNotifier, LeaveHistoryState>(
      LeaveHistoryNotifier.new,
    );
