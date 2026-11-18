import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/paged_list.dart';
import '../../../../core/utils/result.dart';
import '../../../auth/presentation/providers/auth_session_notifier.dart';
import '../../domain/entities/attendance_approval_request.dart';
import '../../domain/entities/time_correction_status.dart';

/// What an attendance approvals tab renders from (#46 off-site, #47 "forgot
/// to scan"), in #19's shape: the requests waiting at the approver's step,
/// then the ones they decided, one of two chips at a time. Each list is its
/// own, a page at a time.
///
/// `my-approvals` answers each status from the caller's own step: `pending`
/// is what still waits on *this* approver (a request they cleared stays
/// pending overall while it sits with HR), `approved` / `rejected` a step
/// they decided. So each list is the server's, never filtered here.
class AttendanceApprovalsState<T extends AttendanceApprovalRequest> {
  const AttendanceApprovalsState({
    this.pending = const AsyncValue.loading(),
    this.decided = const AsyncValue.loading(),
    this.decidedFilter = TimeCorrectionStatus.approved,
    this.rejectOnlyIds = const {},
    this.notMineIds = const {},
  });

  final AsyncValue<PagedList<T>> pending;
  final AsyncValue<PagedList<T>> decided;
  final TimeCorrectionStatus decidedFilter;

  /// Requests that can only be rejected now (an off-site check-out whose
  /// check-in was turned down): Approve goes.
  final Set<String> rejectOnlyIds;

  /// Requests whose step turned out not to be the approver's
  /// (`NOT_APPROVER`): no buttons.
  final Set<String> notMineIds;

  /// The two chips under "decided by me", in order.
  static const List<TimeCorrectionStatus> decidedStatuses = [
    TimeCorrectionStatus.approved,
    TimeCorrectionStatus.rejected,
  ];

  AttendanceApprovalsState<T> copyWith({
    AsyncValue<PagedList<T>>? pending,
    AsyncValue<PagedList<T>>? decided,
    TimeCorrectionStatus? decidedFilter,
    Set<String>? rejectOnlyIds,
    Set<String>? notMineIds,
  }) => AttendanceApprovalsState<T>(
    pending: pending ?? this.pending,
    decided: decided ?? this.decided,
    decidedFilter: decidedFilter ?? this.decidedFilter,
    rejectOnlyIds: rejectOnlyIds ?? this.rejectOnlyIds,
    notMineIds: notMineIds ?? this.notMineIds,
  );
}

/// The two lists of an attendance approvals tab: loaded in parallel, a page
/// at a time, the chip's list from its first page when it changes. Each
/// kind of request says how a page is fetched ([fetch]); decisions go
/// through its `AttendanceDecisionNotifier`, which reads these lists again.
abstract class AttendanceApprovalsNotifier<T extends AttendanceApprovalRequest>
    extends AutoDisposeNotifier<AttendanceApprovalsState<T>> {
  bool _disposed = false;

  /// Loads started per list; an answer to an older one is dropped.
  int _pendingLoads = 0;
  int _decidedLoads = 0;

  /// One page of the approver's list of [status], from [cursor].
  FutureResult<CursorPage<T>> fetch(
    TimeCorrectionStatus status,
    String? cursor,
  );

  @override
  AttendanceApprovalsState<T> build() {
    // Another login starts from nothing.
    ref.watch(
      authSessionProvider.select((s) => s.valueOrNull?.user?.employeeId),
    );
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    Future.microtask(refresh);
    return AttendanceApprovalsState<T>();
  }

  /// Both lists again from their first page: pull to refresh, after a
  /// decision. Rows already shown stay while they load.
  Future<void> refresh() =>
      Future.wait([_loadFirst(_pendingList), _loadFirst(_decidedList)]);

  /// The "decided by me" chip: that list from its first page.
  void selectDecided(TimeCorrectionStatus status) {
    if (status == state.decidedFilter) return;
    state = state.copyWith(
      decidedFilter: status,
      decided: const AsyncValue.loading(),
    );
    _loadFirst(_decidedList);
  }

  Future<void> retryPending() => _loadFirst(_pendingList);
  Future<void> retryDecided() => _loadFirst(_decidedList);
  Future<void> loadMorePending() => _loadMore(_pendingList);
  Future<void> loadMoreDecided() => _loadMore(_decidedList);
  Future<void> retryLoadMorePending() => _retryLoadMore(_pendingList);
  Future<void> retryLoadMoreDecided() => _retryLoadMore(_decidedList);

  /// What a refusal left for request [id]: Reject only, or no buttons
  /// (`NOT_APPROVER`).
  void mark(String id, {bool rejectOnly = false, bool notMine = false}) {
    if (_disposed) return;
    state = state.copyWith(
      rejectOnlyIds: rejectOnly
          ? {...state.rejectOnlyIds, id}
          : state.rejectOnlyIds,
      notMineIds: notMine ? {...state.notMineIds, id} : state.notMineIds,
    );
  }

  /// Takes request [id] out of the waiting list at once: decided, or moved
  /// on without this approver. The reload after it says the rest.
  void dropWaiting(String id) {
    final list = state.pending.valueOrNull;
    if (_disposed || list == null) return;
    state = state.copyWith(
      pending: AsyncValue.data(
        list.withItems([
          for (final r in list.items)
            if (r.id != id) r,
        ]),
      ),
    );
  }

  late final _ApprovalList<T> _pendingList = _ApprovalList<T>(
    status: () => TimeCorrectionStatus.pending,
    read: () => state.pending,
    write: (value) => state = state.copyWith(pending: value),
    nextLoad: () => ++_pendingLoads,
    currentLoad: () => _pendingLoads,
  );

  late final _ApprovalList<T> _decidedList = _ApprovalList<T>(
    status: () => state.decidedFilter,
    read: () => state.decided,
    write: (value) => state = state.copyWith(decided: value),
    nextLoad: () => ++_decidedLoads,
    currentLoad: () => _decidedLoads,
  );

  Future<void> _loadFirst(_ApprovalList<T> list) async {
    final load = list.nextLoad();
    list.write(AsyncLoading<PagedList<T>>().copyWithPrevious(list.read()));
    final result = await fetch(list.status(), null);
    if (_disposed || load != list.currentLoad()) return;
    // A failure keeps the rows already shown.
    list.write(
      result.fold(
        (failure) => AsyncValue<PagedList<T>>.error(
          failure,
          StackTrace.current,
        ).copyWithPrevious(list.read()),
        (page) => AsyncValue.data(PagedList.first(page)),
      ),
    );
  }

  Future<void> _loadMore(_ApprovalList<T> list) async {
    final value = list.read();
    final current = value.valueOrNull;
    if (current == null || !current.canLoadMore || value.isLoading) return;
    final load = list.currentLoad();
    list.write(AsyncValue.data(current.startLoadingMore()));

    final result = await fetch(list.status(), current.nextCursor);
    if (_disposed || load != list.currentLoad()) return;
    final now = list.read().valueOrNull ?? current;
    list.write(AsyncValue.data(result.fold(now.failLoadingMore, now.append)));
  }

  Future<void> _retryLoadMore(_ApprovalList<T> list) async {
    final current = list.read().valueOrNull;
    if (current == null || current.loadMoreError == null) return;
    list.write(AsyncValue.data(current.retryable));
    await _loadMore(list);
  }
}

/// One of the tab's two lists: the status it asks for, where it lives in
/// the state, and its load count.
class _ApprovalList<T> {
  final TimeCorrectionStatus Function() status;
  final AsyncValue<PagedList<T>> Function() read;
  final void Function(AsyncValue<PagedList<T>> value) write;
  final int Function() nextLoad;
  final int Function() currentLoad;

  _ApprovalList({
    required this.status,
    required this.read,
    required this.write,
    required this.nextLoad,
    required this.currentLoad,
  });
}
