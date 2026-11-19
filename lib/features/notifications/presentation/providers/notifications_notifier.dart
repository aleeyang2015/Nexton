import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/paged_list.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/notification_dedupe.dart';
import '../../notifications_providers.dart';
import 'unread_count_notifier.dart';

/// The bell list (#54): the rows loaded so far, and those shown (the copies
/// old rows have collapsed, worked out once per change).
class NotificationsState {
  final AsyncValue<PagedList<AppNotification>> rows;

  NotificationsState(this.rows);

  /// The rows to show: [rows] without the copies old rows come with.
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
    _readHere.clear();
    _allReadInLoad = null;
    _markingAll = false;
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

    // The rows as they are now: one may have been read while this page was
    // on its way.
    final current = state.rows.valueOrNull ?? list;
    _set(
      AsyncValue.data(
        _keepRead(
          result.fold(
            current.failLoadingMore,
            (next) => current.appendNumbered(
              items: next.items,
              page: next.page,
              totalPages: next.totalPages,
              keyOf: _id,
            ),
          ),
        ),
      ),
    );
  }

  /// The ids of rows read on this screen (#55). A list answer that was
  /// asked for before the server knew (a next page, a refresh) still calls
  /// them unread: they stay read here.
  final Set<String> _readHere = {};

  /// The load ([_loads]) during which "mark all as read" was last tapped,
  /// or null. Every row of that load was there to be marked, so its next
  /// pages come in as read too; a later load is the server's own word.
  int? _allReadInLoad;

  /// [list] with the rows read on this screen shown as read.
  PagedList<AppNotification> _keepRead(PagedList<AppNotification> list) {
    final all = _allReadInLoad == _loads;
    if (!all && _readHere.isEmpty) return list;
    if (list.items.every((r) => r.isRead)) return list;
    return list.withItems([
      for (final row in list.items)
        all || _readHere.contains(row.id) ? row.asRead() : row,
    ]);
  }

  /// Shows [list] in place of the rows, a refresh on its way still showing
  /// as one.
  void _replaceRows(PagedList<AppNotification> list) => _set(
    state.rows.isLoading
        ? const AsyncLoading<PagedList<AppNotification>>().copyWithPrevious(
            AsyncValue.data(list),
          )
        : AsyncValue.data(list),
  );

  /// The user opened the row [id] (#55): shown as read at once, the bell's
  /// count one less, and the server told. Nothing for a row already read.
  ///
  /// When the call fails the row stays shown as read on this screen, and
  /// nothing is said: the next load shows the server's truth. Either way the
  /// bell's count is then read again from the server, also when this screen
  /// has been left meanwhile.
  Future<void> markRead(String id) async {
    final list = state.rows.valueOrNull;
    if (list == null || !list.items.any((r) => r.id == id && !r.isRead)) {
      return;
    }
    _readHere.add(id);
    _replaceRows(_keepRead(list));
    final count = ref.read(unreadCountProvider.notifier)..oneRead();

    await ref.read(markNotificationReadUseCaseProvider)(id);
    unawaited(count.markSettled());
  }

  /// A "mark all as read" on its way: a second tap sends nothing more.
  bool _markingAll = false;

  /// "Mark all as read" (#55): every row shown as read at once, the bell's
  /// count zero, and the server told. A failure is handled as in
  /// [markRead].
  Future<void> markAllRead() async {
    if (_markingAll) return;
    _markingAll = true;
    _allReadInLoad = _loads;
    _readHere.addAll([
      for (final row in state.rows.valueOrNull?.items ?? const []) row.id,
    ]);
    final list = state.rows.valueOrNull;
    if (list != null) _replaceRows(_keepRead(list));
    final count = ref.read(unreadCountProvider.notifier)..allRead();

    await ref.read(markAllNotificationsReadUseCaseProvider)();
    _markingAll = false;
    unawaited(count.markSettled());
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
      // As they are now: a row may have been read while it was on its way.
      _set(AsyncValue.data((state.rows.valueOrNull ?? shown).retryable));
      return false;
    }

    _set(
      result.fold(
        (failure) => AsyncValue.error(failure, StackTrace.current),
        (page) => AsyncValue.data(
          _keepRead(
            PagedList.firstNumbered(
              items: page.items,
              page: page.page,
              totalPages: page.totalPages,
              keyOf: _id,
            ),
          ),
        ),
      ),
    );
    // New rows may have come with the list: the bell's count follows (#55).
    if (result.isSuccess) {
      unawaited(ref.read(unreadCountProvider.notifier).refresh());
    }
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
