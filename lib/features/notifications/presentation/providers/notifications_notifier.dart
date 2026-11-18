import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/paged_list.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/notification_dedupe.dart';
import '../../notifications_providers.dart';

/// The bell list (#54): the rows loaded so far, and those shown (the
/// two-phone copies collapsed, worked out once per change).
class NotificationsState {
  final AsyncValue<PagedList<AppNotification>> rows;

  NotificationsState(this.rows);

  /// The rows to show: [rows] without the copies a second phone adds.
  late final List<AppNotification> visible = collapseRepeats(
    rows.valueOrNull?.items ?? const [],
  );
}

/// Loads the bell list page by page (`GET /mobile/notifications`, by page
/// number). AutoDispose, so a sign-out drops the last user's rows.
class NotificationsNotifier extends AutoDisposeNotifier<NotificationsState> {
  bool _disposed = false;

  /// How many times the list has been loaded from page 1. An answer asked
  /// for before the latest of them belongs to a list that is gone.
  int _loads = 0;

  @override
  NotificationsState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    Future.microtask(() {
      if (!_disposed) _loadFirst();
    });
    return NotificationsState(const AsyncLoading());
  }

  /// The first page again after it failed. Nothing while it is on its way.
  void retry() {
    if (state.rows.isLoading) return;
    _loadFirst();
  }

  /// Pull to refresh: page 1 again, the rows on screen kept until it
  /// answers. False when it failed: the rows shown then stay.
  Future<bool> refresh() => _loadFirst(keepRows: true);

  /// The page after the rows loaded, added under them. Nothing when there
  /// is no next page, while one is on its way, or after one failed (that
  /// waits for [retryLoadMore]). An answer for a list reloaded meanwhile is
  /// dropped.
  Future<void> loadMore() async {
    final list = state.rows.valueOrNull;
    final page = list?.nextPage;
    if (list == null ||
        page == null ||
        state.rows.isLoading ||
        !list.canLoadMore) {
      return;
    }

    final loadedAs = _loads;
    _set(AsyncValue.data(list.startLoadingMore()));

    final result = await _fetch(page);
    if (_disposed || loadedAs != _loads) return;

    _set(
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

  /// The Retry under the rows, after a next page failed.
  Future<void> retryLoadMore() async {
    final list = state.rows.valueOrNull;
    if (list == null || list.loadMoreError == null) return;
    _set(AsyncValue.data(list.retryable));
    return loadMore();
  }

  /// True when the first page came; false when it failed or was overtaken.
  Future<bool> _loadFirst({bool keepRows = false}) async {
    final loadedAs = ++_loads;
    final shown = state.rows.valueOrNull;
    _set(
      keepRows
          ? const AsyncLoading<PagedList<AppNotification>>().copyWithPrevious(
              state.rows,
            )
          : const AsyncLoading(),
    );

    final result = await _fetch(1);
    if (_disposed || loadedAs != _loads) return false;

    // A refresh that failed keeps the rows that were on screen, ready to
    // load more again.
    if (keepRows && shown != null && result.isFailure) {
      _set(AsyncValue.data(shown.retryable));
      return false;
    }

    _set(
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

  void _set(AsyncValue<PagedList<AppNotification>> rows) =>
      state = NotificationsState(rows);

  static Object _id(AppNotification row) => row.id;

  Future<Result<NumberedPage<AppNotification>>> _fetch(int page) =>
      ref.read(getNotificationsUseCaseProvider)(page);
}

final notificationsNotifierProvider =
    NotifierProvider.autoDispose<NotificationsNotifier, NotificationsState>(
      NotificationsNotifier.new,
    );
