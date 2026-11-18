import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/network/paged_list.dart';
import '../../../../core/utils/result.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/providers/auth_session_notifier.dart';

/// One list of "My team" (#50): the server's pages as they came, the status
/// chip picked (null: all), and who is looking.
class TeamListState<T, S> {
  const TeamListState({
    this.rows = const AsyncValue.loading(),
    this.status,
    this.user,
    this.keep,
  });

  final AsyncValue<PagedList<T>> rows;
  final S? status;
  final User? user;

  /// Which of the server's rows show (set by the notifier).
  final bool Function(T row, User? user)? keep;

  /// The rows this head sees: their own and (for an HR-head's leave) other
  /// departments' left out.
  List<T> get visible => [
    for (final row in rows.valueOrNull?.items ?? <T>[])
      if (keep == null || keep!(row, user)) row,
  ];

  TeamListState<T, S> copyWith({
    AsyncValue<PagedList<T>>? rows,
    S? status,
    bool clearStatus = false,
  }) => TeamListState<T, S>(
    rows: rows ?? this.rows,
    status: clearStatus ? null : (status ?? this.status),
    user: user,
    keep: keep,
  );
}

/// A "My team" list (#50), read-only: a page at a time, the status as a
/// server filter, rows filtered on the phone after each page ([keeps]).
///
/// A page that leaves fewer rows than a page asks for the next one at once,
/// so the list is never "none" while more exist; the empty text shows only
/// when it has ended. Each kind says how a page is fetched ([first],
/// [next]).
abstract class TeamListNotifier<T, S>
    extends AutoDisposeNotifier<TeamListState<T, S>> {
  bool _disposed = false;
  int _loads = 0;

  /// Rows a page holds.
  static const int pageSize = 20;

  /// The first page of [status] (null: all).
  Future<Result<PagedList<T>>> first(S? status);

  /// [list] with its next page added, or the failure.
  Future<Result<PagedList<T>>> next(PagedList<T> list, S? status);

  /// Whether [row] shows to [user]: never their own; for some kinds, more.
  bool keeps(T row, User? user);

  @override
  TeamListState<T, S> build() {
    // Starts again only when who is looking changes (their id, the
    // departments they head, their HR rights): not on every `/auth/me`
    // answer (a new photo link on resume would reset the chip).
    ref.watch(authSessionProvider.select((s) => _whoKey(s.valueOrNull?.user)));
    final user = ref.read(authSessionProvider).valueOrNull?.user;
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    // Not before the session says who is looking: the filters need it.
    if (user?.employeeId case final String id when id.isNotEmpty) {
      Future.microtask(refresh);
    }
    return TeamListState<T, S>(user: user, keep: keeps);
  }

  static String _whoKey(User? user) => [
    user?.employeeId ?? '',
    ...?user?.headedDepartmentIds,
    '|',
    ...?user?.roles,
    '|',
    ...?user?.permissions,
  ].join(',');

  /// The chip: that status's list from its first page.
  void select(S? status) {
    if (status == state.status) return;
    state = state.copyWith(
      status: status,
      clearStatus: status == null,
      rows: const AsyncValue.loading(),
    );
    refresh();
  }

  /// From the first page again: pull to refresh, Retry. Rows shown stay
  /// while it loads; a failure is returned for the tab to say.
  Future<Failure?> refresh() async {
    final load = ++_loads;
    final shown = state.rows.valueOrNull;
    state = state.copyWith(
      rows: AsyncLoading<PagedList<T>>().copyWithPrevious(state.rows),
    );
    final status = state.status;
    final result = await first(status);
    if (_disposed || load != _loads) return null;
    final failure = result.failureOrNull;
    if (failure != null) {
      state = state.copyWith(
        rows: AsyncValue<PagedList<T>>.error(failure, StackTrace.current)
            .copyWithPrevious(
              shown == null ? state.rows : AsyncValue.data(shown.retryable),
            ),
      );
      return failure;
    }
    final list = result.dataOrNull!;
    state = state.copyWith(rows: AsyncValue.data(list));
    await _fillUp(load, shownBefore: 0);
    return null;
  }

  /// The next page, when there is one and none is on its way (the user
  /// scrolled near the end).
  Future<void> loadMore() => _loadMore(shownBefore: state.visible.length);

  /// [shownBefore]: the rows on screen when the user's action began, so a
  /// load counts what it has added in all.
  Future<void> _loadMore({required int shownBefore}) async {
    final value = state.rows;
    final current = value.valueOrNull;
    if (current == null || !current.canLoadMore || value.isLoading) return;
    final load = _loads;
    state = state.copyWith(rows: AsyncValue.data(current.startLoadingMore()));
    final result = await next(current, state.status);
    if (_disposed || load != _loads) return;
    final now = state.rows.valueOrNull ?? current;
    final failure = result.failureOrNull;
    if (failure != null) {
      state = state.copyWith(
        rows: AsyncValue.data(now.failLoadingMore(failure)),
      );
      return;
    }
    final list = result.dataOrNull!;
    state = state.copyWith(rows: AsyncValue.data(list));
    await _fillUp(load, shownBefore: shownBefore);
  }

  /// The Retry under the rows, after a next page failed.
  Future<void> retryLoadMore() async {
    final current = state.rows.valueOrNull;
    if (current == null || current.loadMoreError == null) return;
    state = state.copyWith(rows: AsyncValue.data(current.retryable));
    await loadMore();
  }

  /// While this load (from the user's action: open, chip, refresh, scroll)
  /// has added fewer rows than a page once filtered, the next page is asked
  /// for at once (the spinner still showing). In all, not per page: one
  /// filtered row on a page must not walk the whole history.
  Future<void> _fillUp(int load, {required int shownBefore}) async {
    if (_disposed || load != _loads) return;
    final list = state.rows.valueOrNull;
    if (list == null || !list.canLoadMore) return;
    if (state.visible.length - shownBefore >= pageSize) return;
    await _loadMore(shownBefore: shownBefore);
  }
}
