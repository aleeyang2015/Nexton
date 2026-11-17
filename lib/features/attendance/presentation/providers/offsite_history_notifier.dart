import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/network/paged_list.dart';
import '../../attendance_providers.dart';
import '../../domain/entities/offsite_detail.dart';
import '../../domain/entities/time_correction_status.dart';
import 'offsite_history_state.dart';

/// "My requests"' off-site tab (#42): the employee's own requests from
/// `GET /attendance/offsite-requests/my`, a page at a time, filtered by the
/// server on the picked status, and the withdrawal of one still pending.
class OffsiteHistoryNotifier extends AutoDisposeNotifier<OffsiteHistoryState> {
  bool _disposed = false;

  /// How many times the list was loaded from its first page; an answer to
  /// an older load (another status was picked since) is dropped.
  int _loads = 0;

  @override
  OffsiteHistoryState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    Future.microtask(refresh);
    return const OffsiteHistoryState();
  }

  /// Shows the requests with [status] (all when null): the server's list for
  /// it, from its first page.
  void selectFilter(TimeCorrectionStatus? status) {
    if (status == state.filter) return;
    state = state.copyWith(
      filter: status,
      requests: const AsyncValue.loading(),
    );
    refresh();
  }

  /// Loads the picked status's list again from its first page: a retry, a
  /// pull to refresh, after a withdrawal. Requests already shown stay while
  /// it loads.
  Future<void> refresh() async {
    final loadedAs = ++_loads;
    state = state.copyWith(
      requests: const AsyncLoading<PagedList<OffsiteRequestDetail>>()
          .copyWithPrevious(state.requests),
    );

    final result = await ref.read(getOffsiteHistoryUseCaseProvider)((
      status: state.filter,
      cursor: null,
    ));
    if (_disposed || loadedAs != _loads) return;

    state = state.copyWith(
      requests: result.fold(
        (failure) => AsyncValue.error(failure, StackTrace.current),
        (page) => AsyncValue.data(PagedList.first(page)),
      ),
    );
  }

  /// The next page, when there is one and none is on its way.
  Future<void> loadMore() async {
    final list = state.requests.valueOrNull;
    if (list == null || !list.canLoadMore || state.requests.isLoading) return;
    final loadedAs = _loads;
    state = state.copyWith(requests: AsyncValue.data(list.startLoadingMore()));

    final result = await ref.read(getOffsiteHistoryUseCaseProvider)((
      status: state.filter,
      cursor: list.nextCursor,
    ));
    if (_disposed || loadedAs != _loads) return;

    final current = state.requests.valueOrNull ?? list;
    state = state.copyWith(
      requests: AsyncValue.data(
        result.fold(current.failLoadingMore, current.append),
      ),
    );
  }

  /// The Retry under the list, after a next page failed.
  Future<void> retryLoadMore() async {
    final list = state.requests.valueOrNull;
    if (list == null || list.loadMoreError == null) return;
    state = state.copyWith(requests: AsyncValue.data(list.retryable));
    await loadMore();
  }

  /// Withdraws [request] (§9). Resolves to null when it went through, else the
  /// failure for the page to report.
  ///
  /// The list is loaded again either way: on success to show the request as
  /// cancelled, and on `CANNOT_CANCEL` because that answer means the row was
  /// stale (approved or already withdrawn since it loaded).
  Future<Failure?> cancel(OffsiteRequestDetail request) async {
    final id = request.id;
    if (state.cancellingIds.contains(id)) return null;
    state = state.copyWith(cancellingIds: {...state.cancellingIds, id});

    final result = await ref.read(cancelOffsiteRequestUseCaseProvider)(id);
    if (_disposed) return result.failureOrNull;

    state = state.copyWith(cancellingIds: {...state.cancellingIds}..remove(id));
    await refresh();
    return result.failureOrNull;
  }
}

final offsiteHistoryNotifierProvider =
    NotifierProvider.autoDispose<OffsiteHistoryNotifier, OffsiteHistoryState>(
      OffsiteHistoryNotifier.new,
    );
