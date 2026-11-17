import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../../../core/network/paged_list.dart';
import '../../../../core/utils/result.dart';
import '../../data/datasources/leave_error_code.dart';
import '../../domain/entities/leave_request.dart';
import '../../domain/entities/leave_status.dart';
import '../../time_off_providers.dart';
import 'leave_approvals_state.dart';

/// Owns the approvals tab's two lists and each decision's in-flight status.
/// The tab renders what comes back and forwards taps here; it holds no
/// fetching logic of its own.
///
/// * **Waiting**: what waits for the signed-in approver now.
/// * **Decided**: what they approved, or rejected ([LeaveDecidedFilter]).
///   The server filters by the approver's own step, so a request they
///   approved stays there after HR decides it or the employee cancels it.
///
/// Each list comes a page at a time. The two first pages are asked for
/// together, not one after the other.
class LeaveApprovalsNotifier extends AutoDisposeNotifier<LeaveApprovalsState> {
  bool _disposed = false;

  /// How many times each list has been loaded from its first page. An answer
  /// asked for before the latest of them belongs to a list that is gone.
  int _pendingLoads = 0;
  int _decidedLoads = 0;

  @override
  LeaveApprovalsState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    Future.microtask(_loadAll);

    // Watched, so another login starts this notifier, and its lists, again.
    return LeaveApprovalsState(
      ownEmployeeId: ref.watch(leaveOwnEmployeeIdProvider),
    );
  }

  /// Re-runs both lists from their first pages.
  void retry() => _loadAll();

  /// Loads the waiting list again from its first page, after it failed. The
  /// decided list, and the pages of it already loaded, are left alone.
  void retryPending() => _loadPending();

  /// Loads the decided list again from its first page, after it failed. The
  /// waiting list is left alone.
  void retryDecided() => _loadDecided();

  /// Shows the requests the approver approved, or the ones they rejected.
  void setDecidedFilter(LeaveDecidedFilter filter) {
    if (filter == state.decidedFilter) return;
    state = state.copyWith(decidedFilter: filter);
    _loadDecided();
  }

  /// The next page of the waiting list. Does nothing when there is none,
  /// while one is on its way, or after one failed (that waits for
  /// [retryLoadMorePending]).
  Future<void> loadMorePending() => _loadMore(_pendingList);

  /// The next page of the decided list; same rules as [loadMorePending].
  Future<void> loadMoreDecided() => _loadMore(_decidedList);

  /// The Retry under the waiting list, after a next page failed.
  Future<void> retryLoadMorePending() => _retryLoadMore(_pendingList);

  /// The Retry under the decided list, after a next page failed.
  Future<void> retryLoadMoreDecided() => _retryLoadMore(_decidedList);

  /// Both first pages, asked for at the same time.
  Future<void> _loadAll() async {
    await Future.wait([_loadPending(), _loadDecided()]);
  }

  Future<void> _loadPending() => _loadFirst(_pendingList);

  Future<void> _loadDecided() => _loadFirst(_decidedList);

  _ApprovalList get _pendingList => _ApprovalList(
    status: () => LeaveStatus.pending,
    read: () => state.pending,
    write: (value) => state = state.copyWith(pending: value),
    loads: () => _pendingLoads,
    nextLoad: () => ++_pendingLoads,
  );

  _ApprovalList get _decidedList => _ApprovalList(
    status: () => state.decidedFilter.status,
    read: () => state.decided,
    write: (value) => state = state.copyWith(decided: value),
    loads: () => _decidedLoads,
    nextLoad: () => ++_decidedLoads,
  );

  Future<void> _loadFirst(_ApprovalList list) async {
    final loadedAs = list.nextLoad();
    list.write(const AsyncValue.loading());

    final result = await ref.read(getLeaveApprovalsUseCaseProvider)((
      status: list.status(),
      cursor: null,
    ));
    if (_disposed || loadedAs != list.loads()) return;

    list.write(
      result.fold(
        (failure) => AsyncValue.error(failure, StackTrace.current),
        (page) => AsyncValue.data(PagedList.first(page)),
      ),
    );
  }

  Future<void> _loadMore(_ApprovalList list) async {
    final current = list.read();
    final rows = current.valueOrNull;
    if (rows == null || current.isLoading || !rows.canLoadMore) return;

    final loadedAs = list.loads();
    list.write(AsyncValue.data(rows.startLoadingMore()));

    final result = await ref.read(getLeaveApprovalsUseCaseProvider)((
      status: list.status(),
      cursor: rows.nextCursor,
    ));
    // The list was reloaded meanwhile (a decision, a retry, the other
    // chip): this page belongs to the one that is gone.
    if (_disposed || loadedAs != list.loads()) return;

    list.write(AsyncValue.data(result.fold(rows.failLoadingMore, rows.append)));
  }

  /// A page the server refused as invalid (`400 VALIDATION_ERROR`: the
  /// cursor is no longer good) cannot be asked for again, so that list
  /// starts over. Anything else asks for the same page.
  Future<void> _retryLoadMore(_ApprovalList list) async {
    final rows = list.read().valueOrNull;
    final error = rows?.loadMoreError;
    if (rows == null || error == null) return;

    if (error is ValidationFailure &&
        error.code == ApiErrorCodes.validationError) {
      return _loadFirst(list);
    }

    list.write(
      AsyncValue.data(
        PagedList(
          items: rows.items,
          nextCursor: rows.nextCursor,
          hasMore: rows.hasMore,
        ),
      ),
    );
    return _loadMore(list);
  }

  /// Approves the waiting step of [request], with [note] when one was
  /// typed (`approver_note`).
  Future<LeaveDecisionOutcome> approve(LeaveRequest request, {String? note}) {
    final trimmed = note?.trim();
    return _decide(
      request.id,
      () => ref.read(approveLeaveStepUseCaseProvider)((
        id: request.id,
        stepId: request.currentStep?.id,
        note: trimmed == null || trimmed.isEmpty ? null : trimmed,
      )),
    );
  }

  Future<LeaveDecisionOutcome> reject(LeaveRequest request, String reason) {
    return _decide(
      request.id,
      () => ref.read(rejectLeaveStepUseCaseProvider)((
        id: request.id,
        reason: reason,
        stepId: request.currentStep?.id,
        note: null,
      )),
    );
  }

  Future<LeaveDecisionOutcome> _decide(
    String requestId,
    Future<Result<LeaveRequest>> Function() action,
  ) async {
    // A second tap before the button has had a frame to switch off. One
    // decision per request at a time: the second would be refused as stale
    // and tell the approver "no longer waiting" after their own approval.
    if (state.decidingIds.contains(requestId)) return LeaveDecisionOutcome.gone;

    state = state.copyWith(decidingIds: {...state.decidingIds, requestId});

    final result = await action();
    if (_disposed) return LeaveDecisionOutcome.gone;

    state = state.copyWith(
      decidingIds: {...state.decidingIds}..remove(requestId),
    );

    return result.fold(
      (failure) async {
        // The card the approver tapped is out of date. Reload first, so it
        // is gone or corrected by the time the reason is shown; otherwise
        // every retry would fail the same way.
        if (LeaveErrorCode.isStaleForApprover(failure)) {
          await _loadAll();
          return LeaveDecisionOutcome.reloaded(failure);
        }
        return LeaveDecisionOutcome.failed(failure);
      },
      (_) async {
        await _loadAll();
        return LeaveDecisionOutcome.success;
      },
    );
  }
}

/// One of the two lists, as the notifier's shared load code sees it: which
/// status it asks for, where it lives in the state, and its load count.
class _ApprovalList {
  final LeaveStatus Function() status;
  final AsyncValue<PagedList<LeaveRequest>> Function() read;
  final void Function(AsyncValue<PagedList<LeaveRequest>> value) write;
  final int Function() loads;
  final int Function() nextLoad;

  const _ApprovalList({
    required this.status,
    required this.read,
    required this.write,
    required this.loads,
    required this.nextLoad,
  });
}

final leaveApprovalsNotifierProvider =
    NotifierProvider.autoDispose<LeaveApprovalsNotifier, LeaveApprovalsState>(
      LeaveApprovalsNotifier.new,
    );
