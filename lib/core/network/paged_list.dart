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
/// Two ways to go on, by what the server hands out: a cursor ([nextCursor],
/// from [first] and [append]) or a page number ([nextPage], from
/// [PagedList.firstNumbered] and [appendNumbered]: the OT lists). A list
/// uses one or the other.
///
/// Immutable; every change gives a new list, so a notifier can put it in its
/// state.
class PagedList<T> {
  final List<T> items;
  final String? nextCursor;

  /// The page number to ask for next, for a list that pages by number. Null
  /// on the last page, and for a list that pages by cursor.
  final int? nextPage;
  final bool hasMore;

  /// True while the next page is being fetched.
  final bool loadingMore;

  /// Why the last fetch of a next page failed; null when it did not. The
  /// rows already loaded stay.
  final Object? loadMoreError;

  const PagedList({
    this.items = const [],
    this.nextCursor,
    this.nextPage,
    this.hasMore = false,
    this.loadingMore = false,
    this.loadMoreError,
  });

  /// The list after its first page. A first page with no rows is the whole
  /// list, whatever it says about there being more (see [append]).
  factory PagedList.first(CursorPage<T> page) => PagedList<T>().append(page);

  /// The list after its first page, for a list that pages by number
  /// (`meta {page, total_pages}`).
  factory PagedList.firstNumbered({
    required List<T> items,
    required int page,
    required int totalPages,
    Object Function(T item)? keyOf,
  }) => PagedList<T>().appendNumbered(
    items: items,
    page: page,
    totalPages: totalPages,
    keyOf: keyOf,
  );

  /// True when a next page may be asked for now: there is one, none is on
  /// its way, and the last try did not fail (that one waits for a Retry, so
  /// a list scrolled to its end does not ask again and again).
  bool get canLoadMore => hasMore && !loadingMore && loadMoreError == null;

  /// How many rows there are, as far as is known: the number loaded, with a
  /// `+` when there are more to load (`20+`). A header and a badge that both
  /// show this never disagree.
  String get countLabel => '${items.length}${hasMore ? '+' : ''}';

  /// The list while its next page is on the way.
  PagedList<T> startLoadingMore() => PagedList(
    items: items,
    nextCursor: nextCursor,
    nextPage: nextPage,
    hasMore: hasMore,
    loadingMore: true,
  );

  /// The list with [page] added after the rows it already has, in the order
  /// the server sent them, and the cursor moved on.
  ///
  /// A page with no rows ends the list, whatever it says about there being
  /// more: a screen that asks for the next page whenever its end is in view
  /// would otherwise ask for ever while nothing new appears. So does a page
  /// that hands back the cursor it was asked with: going on would fetch the
  /// same rows again.
  PagedList<T> append(CursorPage<T> page) {
    final goesOn =
        page.hasMore &&
        page.items.isNotEmpty &&
        page.nextCursor != nextCursor;
    return PagedList(
      items: [...items, ...page.items],
      nextCursor: goesOn ? page.nextCursor : null,
      hasMore: goesOn,
    );
  }

  /// The list with page number [page] of [totalPages] added after the rows
  /// it already has.
  ///
  /// It ends when [page] is the last, when the page has no rows (as
  /// [append]), or when [page] is not past the pages already loaded: asking
  /// on would fetch the same rows again.
  ///
  /// With [keyOf], a row whose key is already in the list is left out: a
  /// list paged by position repeats a row when one is added at its top
  /// between two pages.
  PagedList<T> appendNumbered({
    required List<T> items,
    required int page,
    required int totalPages,
    Object Function(T item)? keyOf,
  }) {
    final movedOn = nextPage == null || page >= nextPage!;
    final goesOn = page < totalPages && items.isNotEmpty && movedOn;
    final seen = keyOf == null ? null : {for (final i in this.items) keyOf(i)};
    final added = seen == null
        ? items
        : [
            for (final item in items)
              if (seen.add(keyOf!(item))) item,
          ];
    return PagedList(
      items: [...this.items, ...added],
      nextPage: goesOn ? page + 1 : null,
      hasMore: goesOn,
    );
  }

  /// The list after its next page failed: the rows and where to go on from
  /// stay, so a Retry asks for the same page.
  PagedList<T> failLoadingMore(Object error) => PagedList(
    items: items,
    nextCursor: nextCursor,
    nextPage: nextPage,
    hasMore: hasMore,
    loadMoreError: error,
  );

  /// The list with its load-more error cleared, for a Retry to ask for the
  /// same page again.
  PagedList<T> get retryable => PagedList(
    items: items,
    nextCursor: nextCursor,
    nextPage: nextPage,
    hasMore: hasMore,
  );
}
