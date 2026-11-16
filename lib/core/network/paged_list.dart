import 'api_response.dart';

/// One page of a list the server hands out a piece at a time, with a cursor
/// to ask for the next piece.
///
/// Plain Dart, no Dio: a repository may return it and the domain layer may
/// pass it on. Lists that page by number add their own page type to this
/// file.
class CursorPage<T> {
  final List<T> items;

  /// What to send back as `cursor` to get the page after this one. Null on
  /// the last page.
  final String? nextCursor;

  /// True when there is a page after this one that can be asked for.
  final bool hasMore;

  const CursorPage({
    required this.items,
    this.nextCursor,
    this.hasMore = false,
  });

  /// A whole list in one page: nothing more to ask for.
  const CursorPage.single(this.items) : nextCursor = null, hasMore = false;

  /// Reads a cursor-mode answer: `data` is the list, and
  /// `meta = { has_more, next_cursor }` says whether to go on. The server
  /// leaves `next_cursor` out on the last page.
  ///
  /// An answer with no `meta` is one page with no more. So is one that says
  /// `has_more` but gives no cursor: there would be nothing to ask with.
  static CursorPage<T> fromBody<T>(
    dynamic body,
    T Function(Map<String, dynamic> json) parse,
  ) {
    final items = ApiEnvelope.unwrapList(body).map(parse).toList();

    final meta = body is Map ? body['meta'] : null;
    final cursor = meta is Map ? meta['next_cursor'] : null;
    final nextCursor = cursor is String && cursor.isNotEmpty ? cursor : null;
    final hasMore =
        meta is Map && meta['has_more'] == true && nextCursor != null;

    return CursorPage(
      items: items,
      nextCursor: hasMore ? nextCursor : null,
      hasMore: hasMore,
    );
  }
}

/// A list as a screen holds it while it loads page after page: the rows so
/// far, where to go on from, and how the page being fetched is doing.
///
/// Immutable; every change gives a new list, so a notifier can put it in its
/// state.
class PagedList<T> {
  final List<T> items;
  final String? nextCursor;
  final bool hasMore;

  /// True while the next page is being fetched.
  final bool loadingMore;

  /// Why the last fetch of a next page failed; null when it did not. The
  /// rows already loaded stay.
  final Object? loadMoreError;

  const PagedList({
    this.items = const [],
    this.nextCursor,
    this.hasMore = false,
    this.loadingMore = false,
    this.loadMoreError,
  });

  /// The list after its first page.
  factory PagedList.first(CursorPage<T> page) => PagedList(
    items: page.items,
    nextCursor: page.nextCursor,
    hasMore: page.hasMore,
  );

  /// True when a next page may be asked for now: there is one, none is on
  /// its way, and the last try did not fail (that one waits for a Retry, so
  /// a list scrolled to its end does not ask again and again).
  bool get canLoadMore => hasMore && !loadingMore && loadMoreError == null;

  /// The list while its next page is on the way.
  PagedList<T> startLoadingMore() => PagedList(
    items: items,
    nextCursor: nextCursor,
    hasMore: hasMore,
    loadingMore: true,
  );

  /// The list with [page] added after the rows it already has, in the order
  /// the server sent them, and the cursor moved on.
  PagedList<T> append(CursorPage<T> page) => PagedList(
    items: [...items, ...page.items],
    nextCursor: page.nextCursor,
    hasMore: page.hasMore,
  );

  /// The list after its next page failed: the rows and the cursor stay, so
  /// a Retry asks for the same page.
  PagedList<T> failLoadingMore(Object error) => PagedList(
    items: items,
    nextCursor: nextCursor,
    hasMore: hasMore,
    loadMoreError: error,
  );
}
