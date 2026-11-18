import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/network/paged_list.dart';
import '../../attendance_providers.dart';
import '../../domain/entities/time_correction_record.dart';
import '../../domain/entities/time_correction_status.dart';
import 'time_correction_history_state.dart';

/// "My requests"' "forgot to scan" tab (#45): the employee's own requests
/// from `GET /attendance/correction-requests/my`, a page at a time, filtered
/// by the server on the picked status.
class TimeCorrectionHistoryNotifier
    extends AutoDisposeNotifier<TimeCorrectionHistoryState> {
  bool _disposed = false;

  /// How many times the list was loaded from its first page; an answer to
  /// an older load (another status was picked since) is dropped.
  int _loads = 0;

  @override
  TimeCorrectionHistoryState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    Future.microtask(refresh);
    return const TimeCorrectionHistoryState();
  }

  /// Shows the requests with [status] (all when null): the server's list for
  /// it, from its first page.
  void selectFilter(TimeCorrectionStatus? status) {
    if (status == state.filter) return;
    state = state.copyWith(filter: status, records: const AsyncValue.loading());
    refresh();
  }

  /// Loads the picked status's list again from its first page: a retry, a
  /// pull to refresh, after a withdrawal. Requests already shown stay while
  /// it loads.
  ///
  /// A failure with rows already shown keeps them, and is returned for the
  /// page to say.
  Future<Failure?> refresh() async {
    final loadedAs = ++_loads;
    state = state.copyWith(
      records: const AsyncLoading<PagedList<TimeCorrectionRecord>>()
          .copyWithPrevious(state.records),
    );

    final result = await ref.read(getTimeCorrectionHistoryUseCaseProvider)((
      status: state.filter,
      cursor: null,
    ));
    if (_disposed || loadedAs != _loads) return null;

    state = state.copyWith(
      records: result.fold(
        (failure) => AsyncValue<PagedList<TimeCorrectionRecord>>.error(
          failure,
          StackTrace.current,
        ).copyWithPrevious(state.records),
        (page) => AsyncValue.data(PagedList.first(page)),
      ),
    );
    return result.failureOrNull;
  }

  /// The next page, when there is one and none is on its way.
  Future<void> loadMore() async {
    final list = state.records.valueOrNull;
    if (list == null || !list.canLoadMore || state.records.isLoading) return;
    final loadedAs = _loads;
    state = state.copyWith(records: AsyncValue.data(list.startLoadingMore()));

    final result = await ref.read(getTimeCorrectionHistoryUseCaseProvider)((
      status: state.filter,
      cursor: list.nextCursor,
    ));
    if (_disposed || loadedAs != _loads) return;

    final current = state.records.valueOrNull ?? list;
    state = state.copyWith(
      records: AsyncValue.data(
        result.fold(current.failLoadingMore, current.append),
      ),
    );
  }

  /// The Retry under the list, after a next page failed.
  Future<void> retryLoadMore() async {
    final list = state.records.valueOrNull;
    if (list == null || list.loadMoreError == null) return;
    state = state.copyWith(records: AsyncValue.data(list.retryable));
    await loadMore();
  }
}

final timeCorrectionHistoryNotifierProvider =
    NotifierProvider.autoDispose<
      TimeCorrectionHistoryNotifier,
      TimeCorrectionHistoryState
    >(TimeCorrectionHistoryNotifier.new);
