import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/paged_list.dart';
import '../../attendance_providers.dart';
import '../../domain/entities/offsite_detail.dart';
import '../../domain/entities/time_correction_status.dart';
import 'offsite_approvals_state.dart';

/// The approvals page's off-site tab (#46): the scans waiting at the
/// approver's step and the ones they decided, from
/// `GET /attendance/offsite-requests/my-approvals`, each list a page at a
/// time and loaded in parallel. Decisions go through
/// `OffsiteDecisionNotifier`, which reads these lists again after one.
class OffsiteApprovalsNotifier
    extends AutoDisposeNotifier<OffsiteApprovalsState> {
  bool _disposed = false;

  /// Loads started per list; an answer to an older one is dropped.
  int _pendingLoads = 0;
  int _decidedLoads = 0;

  @override
  OffsiteApprovalsState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    Future.microtask(refresh);
    return const OffsiteApprovalsState();
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

  /// A check-out that can only be rejected now (`CHECKIN_NOT_APPROVED`).
  void markRejectOnly(String id) {
    if (_disposed) return;
    state = state.copyWith(rejectOnlyIds: {...state.rejectOnlyIds, id});
  }

  late final _OffsiteList _pendingList = _OffsiteList(
    status: () => TimeCorrectionStatus.pending,
    read: () => state.pending,
    write: (value) => state = state.copyWith(pending: value),
    nextLoad: () => ++_pendingLoads,
    currentLoad: () => _pendingLoads,
  );

  late final _OffsiteList _decidedList = _OffsiteList(
    status: () => state.decidedFilter,
    read: () => state.decided,
    write: (value) => state = state.copyWith(decided: value),
    nextLoad: () => ++_decidedLoads,
    currentLoad: () => _decidedLoads,
  );

  Future<void> _loadFirst(_OffsiteList list) async {
    final load = list.nextLoad();
    list.write(
      const AsyncLoading<PagedList<OffsiteRequestDetail>>().copyWithPrevious(
        list.read(),
      ),
    );
    final result = await ref.read(getOffsiteApprovalsUseCaseProvider)((
      status: list.status(),
      cursor: null,
    ));
    if (_disposed || load != list.currentLoad()) return;
    list.write(
      result.fold(
        (failure) => AsyncValue.error(failure, StackTrace.current),
        (page) => AsyncValue.data(PagedList.first(page)),
      ),
    );
  }

  Future<void> _loadMore(_OffsiteList list) async {
    final value = list.read();
    final current = value.valueOrNull;
    if (current == null || !current.canLoadMore || value.isLoading) return;
    final load = list.currentLoad();
    list.write(AsyncValue.data(current.startLoadingMore()));

    final result = await ref.read(getOffsiteApprovalsUseCaseProvider)((
      status: list.status(),
      cursor: current.nextCursor,
    ));
    if (_disposed || load != list.currentLoad()) return;
    final now = list.read().valueOrNull ?? current;
    list.write(AsyncValue.data(result.fold(now.failLoadingMore, now.append)));
  }

  Future<void> _retryLoadMore(_OffsiteList list) async {
    final current = list.read().valueOrNull;
    if (current == null || current.loadMoreError == null) return;
    list.write(AsyncValue.data(current.retryable));
    await _loadMore(list);
  }
}

/// One of the tab's two lists: the status it asks for, where it lives in
/// the state, and its load count.
class _OffsiteList {
  final TimeCorrectionStatus Function() status;
  final AsyncValue<PagedList<OffsiteRequestDetail>> Function() read;
  final void Function(AsyncValue<PagedList<OffsiteRequestDetail>> value) write;
  final int Function() nextLoad;
  final int Function() currentLoad;

  _OffsiteList({
    required this.status,
    required this.read,
    required this.write,
    required this.nextLoad,
    required this.currentLoad,
  });
}

final offsiteApprovalsNotifierProvider =
    NotifierProvider.autoDispose<
      OffsiteApprovalsNotifier,
      OffsiteApprovalsState
    >(OffsiteApprovalsNotifier.new);
