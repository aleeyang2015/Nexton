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

  /// Puts [request] in place of its row, as the request's page last loaded
  /// it: no request, and the pages already loaded stay. A row that no
  /// longer fits the filters (its status or month changed) leaves the list.
  /// Nothing happens when the request is not in the list.
  void showRow(OtRequest request) {
    final list = state.requests.valueOrNull;
    if (list == null) return;
    final index = list.items.indexWhere((r) => r.id == request.id);
    if (index < 0) return;
    if (!_fits(request)) return dropRow(request.id);
    if (list.items[index] == request) return;
    final items = [...list.items]..[index] = request;
    state = state.withRequests(AsyncValue.data(list.withItems(items)));
  }

  /// Takes the row of [id] out: the request is gone (`404`).
  void dropRow(String id) {
    final list = state.requests.valueOrNull;
    if (list == null || !list.items.any((r) => r.id == id)) return;
    final items = [
      for (final r in list.items)
        if (r.id != id) r,
    ];
    state = state.withRequests(AsyncValue.data(list.withItems(items)));
  }

  bool _fits(OtRequest request) {
    final status = state.status;
    final month = state.month;
    final day = request.workDate;
    if (status != null && request.status != status) return false;
    if (month != null &&
        (day == null || day.year != month.year || day.month != month.month)) {
      return false;
    }
    return true;
  }

  /// Asks for the first page again after it failed. Does nothing while it
  /// is already being asked for.
  void retry() {
    if (state.requests.isLoading) return;
    _loadFirst();
  }

  /// Pull to refresh: page 1 again with the same filters, the rows on
  /// screen kept until it answers. False when it failed: the rows already
  /// on screen then stay, and the page says it could not load.
  Future<bool> refresh() => _loadFirst(keepRows: true);

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
            keyOf: _id,
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

  /// True when the first page came, false when it failed or was overtaken.
  Future<bool> _loadFirst({bool keepRows = false}) async {
    final loadedAs = ++_loads;
    final shown = state.requests.valueOrNull;
    state = state.withRequests(
      keepRows
          ? const AsyncLoading<PagedList<OtRequest>>().copyWithPrevious(
              state.requests,
            )
          : const AsyncLoading(),
    );

    final result = await _fetch(1);
    if (_disposed || loadedAs != _loads) return false;

    // A refresh that failed keeps the rows that were on screen.
    if (keepRows && shown != null && result.isFailure) {
      state = state.withRequests(AsyncValue.data(shown));
      return false;
    }

    state = state.withRequests(
      result.fold(
        (failure) => AsyncValue.error(failure, StackTrace.current),
        (page) => AsyncValue.data(
          PagedList.firstNumbered(
            items: page.items,
            page: page.page,
            totalPages: page.totalPages,
            keyOf: _id,
          ),
        ),
      ),
    );
    return result.isSuccess;
  }

  static Object _id(OtRequest request) => request.id;

  Future<Result<OtPage<OtRequest>>> _fetch(int page) =>
      ref.read(getMyOtRequestsUseCaseProvider)(
        MyOtRequestsQuery(status: state.status, month: state.month, page: page),
      );
}

final otListNotifierProvider =
    NotifierProvider.autoDispose<OtListNotifier, OtListState>(
      OtListNotifier.new,
    );
