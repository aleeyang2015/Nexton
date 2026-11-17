import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/paged_list.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/ot_page.dart';
import '../../domain/entities/ot_post.dart';
import '../../domain/entities/ot_request.dart';
import '../../overtime_providers.dart';
import '../widgets/ot_post_button.dart';
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
  /// say what happened; null when nothing was sent: a join (for any post)
  /// is already on its way (one at a time), or the post as now shown no
  /// longer offers Join (the posts were reloaded while the question was
  /// open).
  ///
  /// The posts reload after any answer: a join shows on its card; full,
  /// closed, gone, OT switched off or a join from elsewhere change the
  /// card; and an answer lost on the way may hide a join that was made.
  /// The OT list, when open, reloads after a join, so the join is there,
  /// also when the user left this page while it was on its way.
  Future<Result<OtRequest>?> join(String postId) async {
    if (state.joiningId != null) return null;
    final post = state.posts.valueOrNull?.items
        .where((p) => p.id == postId)
        .firstOrNull;
    if (post != null && OtPostButton.of(post) != OtPostButton.join) {
      return null;
    }
    // Read now: after the page is closed this notifier can reach nothing.
    final list = ref.exists(otListNotifierProvider)
        ? ref.read(otListNotifierProvider.notifier)
        : null;
    state = state.withJoining(postId);

    final result = await ref.read(joinOtPostUseCaseProvider)(postId);
    if (result.isSuccess) list?.refresh();
    if (_disposed) return result;
    state = state.withJoining(null);
    await _loadFirst(keepRows: true);
    return result;
  }

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

    // A reload that failed puts back the posts that were shown, ready to
    // load more again: a next page that was on its way was dropped.
    if (keepRows && shown != null && result.isFailure) {
      state = state.withPosts(AsyncValue.data(shown.retryable));
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
