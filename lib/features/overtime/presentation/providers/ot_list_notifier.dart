import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/paged_list.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/ot_page.dart';
import '../../domain/entities/ot_request.dart';
import '../../domain/usecases/get_my_ot_requests_usecase.dart';
import '../../overtime_providers.dart';
import 'ot_list_state.dart';

/// Owns the OT list's filters and the requests loaded so far, page by page
/// (`GET /ot-requests/my`). The page renders what comes back and forwards
/// taps here.
///
/// AutoDispose, so a sign-out drops the last user's requests.
class OtListNotifier extends AutoDisposeNotifier<OtListState> {
  bool _disposed = false;

  /// How many times the list has been loaded from its first page. An answer
  /// asked for before the latest of them belongs to a list that is gone.
  int _loads = 0;

  @override
  OtListState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    Future.microtask(() {
      if (!_disposed) _loadFirst();
    });
    return const OtListState();
  }

  /// A status chip: null is every status. Asks again from page 1, unless it
  /// is the status already on.
  void setStatus(OtStatus? status) {
    if (status == state.status) return;
    state = state.withFilters(status: status, month: state.month);
    _loadFirst();
  }

  /// The month filter: any day of the month, or null for every month.
  void setMonth(DateTime? month) {
    final first = month == null ? null : DateTime(month.year, month.month);
    if (first == state.month) return;
    state = state.withFilters(status: state.status, month: first);
    _loadFirst();
  }

  /// Asks for the first page again after it failed.
  void retry() => _loadFirst();

  /// Pull to refresh: page 1 again with the same filters, the rows on
  /// screen kept until it answers.
  Future<void> refresh() => _loadFirst(keepRows: true);

  /// Fetches the page after the rows shown and adds it under them. Does
  /// nothing when there is no next page, while one is on its way, or after
  /// one failed (that waits for [retryLoadMore]). An answer for filters the
  /// user has since left, or for a list reloaded meanwhile, is dropped.
  Future<void> loadMore() async {
    final list = state.requests.valueOrNull;
    final page = list?.nextPage;
    if (list == null ||
        page == null ||
        state.requests.isLoading ||
        !list.canLoadMore) {
      return;
    }

    final loadedAs = _loads;
    state = state.withRequests(AsyncValue.data(list.startLoadingMore()));

    final result = await _fetch(page);
    if (_disposed || loadedAs != _loads) return;

    state = state.withRequests(
      AsyncValue.data(
        result.fold(
          list.failLoadingMore,
          (next) => list.appendNumbered(
            items: next.items,
            page: next.page,
            totalPages: next.totalPages,
          ),
        ),
      ),
    );
  }

  /// The Retry under the rows, after a next page failed: asks for the same
  /// page again.
  Future<void> retryLoadMore() async {
    final list = state.requests.valueOrNull;
    if (list == null || list.loadMoreError == null) return;
    state = state.withRequests(AsyncValue.data(list.retryable));
    return loadMore();
  }

  Future<void> _loadFirst({bool keepRows = false}) async {
    final loadedAs = ++_loads;
    state = state.withRequests(
      keepRows
          ? const AsyncLoading<PagedList<OtRequest>>().copyWithPrevious(
              state.requests,
            )
          : const AsyncLoading(),
    );

    final result = await _fetch(1);
    if (_disposed || loadedAs != _loads) return;

    state = state.withRequests(
      result.fold(
        (failure) => AsyncValue.error(failure, StackTrace.current),
        (page) => AsyncValue.data(
          PagedList.firstNumbered(
            items: page.items,
            page: page.page,
            totalPages: page.totalPages,
          ),
        ),
      ),
    );
  }

  Future<Result<OtPage<OtRequest>>> _fetch(int page) =>
      ref.read(getMyOtRequestsUseCaseProvider)(
        MyOtRequestsQuery(status: state.status, month: state.month, page: page),
      );
}

final otListNotifierProvider =
    NotifierProvider.autoDispose<OtListNotifier, OtListState>(
      OtListNotifier.new,
    );
