import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/network/paged_list.dart';
import '../../../../core/utils/result.dart';
import '../../data/datasources/ot_error_code.dart';
import '../../domain/entities/ot_page.dart';
import '../../domain/entities/ot_post.dart';
import '../../domain/entities/ot_request.dart';
import '../../overtime_providers.dart';
import 'ot_detail_notifier.dart';
import 'ot_list_notifier.dart';
import 'ot_posts_state.dart';

/// HR's open OT posts for the user's department (`GET
/// /ot-announcements/open`), soonest start first, page by page, and joining
/// one (`POST /ot-announcements/:id/join`).
///
/// No rule is checked here: the card's button follows the server's
/// `join_open`, `full` and `my_join`, and a join's refusal is returned for
/// the page to say.
///
/// AutoDispose, so a sign-out drops it.
class OtPostsNotifier extends AutoDisposeNotifier<OtPostsState> {
  bool _disposed = false;
  int _loads = 0;

  @override
  OtPostsState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    Future.microtask(() {
      if (!_disposed) _loadFirst();
    });
    return const OtPostsState();
  }

  /// Asks for the first page again after it failed. Does nothing while it
  /// is already being asked for.
  void retry() {
    if (state.posts.isLoading) return;
    _loadFirst();
  }

  /// Pull to refresh: the posts on screen stay until it answers, and stay
  /// when it fails. False when it failed.
  Future<bool> refresh() => _loadFirst(keepRows: true);

  /// The page after the posts shown. Nothing while one is on its way, after
  /// one failed (that waits for [retryLoadMore]), or at the end.
  Future<void> loadMore() async {
    final list = state.posts.valueOrNull;
    final page = list?.nextPage;
    if (list == null ||
        page == null ||
        state.posts.isLoading ||
        !list.canLoadMore) {
      return;
    }

    final loadedAs = _loads;
    state = state.withPosts(AsyncValue.data(list.startLoadingMore()));
    final result = await _fetch(page);
    if (_disposed || loadedAs != _loads) return;

    state = state.withPosts(
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

  /// The Retry under the posts, after a next page failed.
  Future<void> retryLoadMore() async {
    final list = state.posts.valueOrNull;
    if (list == null || list.loadMoreError == null) return;
    state = state.withPosts(AsyncValue.data(list.retryable));
    return loadMore();
  }

  /// Asks to join [postId]. Returns the server's answer, for the page to
  /// say what happened; null when a join (for any post) is already on its
  /// way: one at a time.
  ///
  /// The posts reload after a join, so the card shows it, and after a
  /// refusal that means the card is out of date (full, closed, or gone).
  /// The OT list, when open, reloads after a join, so the join is there.
  Future<Result<OtRequest>?> join(String postId) async {
    if (state.joiningId != null) return null;
    state = state.withJoining(postId);

    final result = await ref.read(joinOtPostUseCaseProvider)(postId);
    if (_disposed) return result;
    state = state.withJoining(null);

    final outOfDate = result.fold(_isOutOfDate, (_) => true);
    if (result.isSuccess && ref.exists(otListNotifierProvider)) {
      ref.read(otListNotifierProvider.notifier).refresh();
    }
    if (outOfDate) await _loadFirst(keepRows: true);
    return result;
  }

  /// The post is full, closed to joining, or gone (`404`).
  static bool _isOutOfDate(Failure failure) =>
      OtDetailNotifier.isGone(failure) ||
      (failure is ValidationFailure &&
          (failure.message == OtErrorCode.tokenFull ||
              failure.message == OtErrorCode.tokenJoinClosed));

  Future<bool> _loadFirst({bool keepRows = false}) async {
    final loadedAs = ++_loads;
    final shown = state.posts.valueOrNull;
    state = state.withPosts(
      keepRows
          ? const AsyncLoading<PagedList<OtPost>>().copyWithPrevious(
              state.posts,
            )
          : const AsyncLoading(),
    );

    final result = await _fetch(1);
    if (_disposed || loadedAs != _loads) return false;

    if (keepRows && shown != null && result.isFailure) {
      state = state.withPosts(AsyncValue.data(shown));
      return false;
    }
    state = state.withPosts(
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

  Future<Result<OtPage<OtPost>>> _fetch(int page) =>
      ref.read(getOpenOtPostsUseCaseProvider)(page);

  static Object _id(OtPost post) => post.id;
}

final otPostsNotifierProvider =
    NotifierProvider.autoDispose<OtPostsNotifier, OtPostsState>(
      OtPostsNotifier.new,
    );
