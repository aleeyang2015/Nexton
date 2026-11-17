import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/network/paged_list.dart';

void main() {
  int id(Map<String, dynamic> json) => json['id'] as int;

  Map<String, dynamic> body(List<int> ids, {Map<String, dynamic>? meta}) => {
    'success': true,
    'data': [
      for (final i in ids) {'id': i},
    ],
    if (meta != null) 'meta': meta,
  };

  group('CursorPage.fromBody', () {
    test('reads the rows, has_more and next_cursor', () {
      final page = CursorPage.fromBody(
        body(
          [1, 2, 3],
          meta: {'per_page': 3, 'has_more': true, 'next_cursor': 'abc'},
        ),
        id,
      );

      expect(page.items, [1, 2, 3]);
      expect(page.hasMore, isTrue);
      expect(page.nextCursor, 'abc');
    });

    test('the last page: has_more false and no next_cursor', () {
      final page = CursorPage.fromBody(
        body([4, 5], meta: {'per_page': 3, 'has_more': false}),
        id,
      );

      expect(page.items, [4, 5]);
      expect(page.hasMore, isFalse);
      expect(page.nextCursor, isNull);
    });

    test('no meta at all is one page with no more', () {
      final page = CursorPage.fromBody(body([1]), id);

      expect(page.items, [1]);
      expect(page.hasMore, isFalse);
      expect(page.nextCursor, isNull);
    });

    test('has_more with no cursor to ask with is the end', () {
      for (final meta in [
        {'has_more': true},
        {'has_more': true, 'next_cursor': ''},
        {'has_more': true, 'next_cursor': 7},
      ]) {
        final page = CursorPage.fromBody(body([1], meta: meta), id);

        expect(page.hasMore, isFalse, reason: '$meta');
        expect(page.nextCursor, isNull, reason: '$meta');
      }
    });

    test('a cursor on a page that says there is no more is not kept', () {
      final page = CursorPage.fromBody(
        body([1], meta: {'has_more': false, 'next_cursor': 'abc'}),
        id,
      );

      expect(page.hasMore, isFalse);
      expect(page.nextCursor, isNull);
    });

    test('an empty page is a page', () {
      final page = CursorPage.fromBody(body([], meta: {'has_more': false}), id);

      expect(page.items, isEmpty);
      expect(page.hasMore, isFalse);
    });

    test('a bare list, with no envelope, is one page', () {
      final page = CursorPage.fromBody([
        {'id': 9},
      ], id);

      expect(page.items, [9]);
      expect(page.hasMore, isFalse);
    });

    test('an error body is not a page', () {
      expect(
        () => CursorPage.fromBody({
          'success': false,
          'error': {'code': 'X', 'message': 'no'},
        }, id),
        throwsFormatException,
      );
    });
  });

  group('PagedList', () {
    const first = CursorPage(items: [1, 2], nextCursor: 'c-2', hasMore: true);

    test('starts from the first page', () {
      final list = PagedList.first(first);

      expect(list.items, [1, 2]);
      expect(list.nextCursor, 'c-2');
      expect(list.hasMore, isTrue);
      expect(list.loadingMore, isFalse);
      expect(list.loadMoreError, isNull);
      expect(list.canLoadMore, isTrue);
    });

    test('a first page with no rows is the whole list, even if it says '
        'there is more: no "0+"', () {
      final list = PagedList<int>.first(
        const CursorPage(items: [], nextCursor: 'c-2', hasMore: true),
      );

      expect(list.hasMore, isFalse);
      expect(list.canLoadMore, isFalse);
      expect(list.countLabel, '0');
    });

    test('the count is the rows loaded, with + while there are more', () {
      expect(PagedList.first(first).countLabel, '2+');
      expect(
        PagedList.first(first).append(const CursorPage(items: [3])).countLabel,
        '3',
      );
    });

    test('append keeps the order and moves the cursor on', () {
      final list = PagedList.first(first).startLoadingMore().append(
        const CursorPage(items: [3, 4], nextCursor: 'c-3', hasMore: true),
      );

      expect(list.items, [1, 2, 3, 4]);
      expect(list.nextCursor, 'c-3');
      expect(list.hasMore, isTrue);
      expect(list.loadingMore, isFalse);
    });

    test('appending the last page ends the list', () {
      final list = PagedList.first(first).append(const CursorPage(items: [3]));

      expect(list.items, [1, 2, 3]);
      expect(list.hasMore, isFalse);
      expect(list.nextCursor, isNull);
      expect(list.canLoadMore, isFalse);
    });

    test('a page with no rows ends the list, even if it says there is more',
        () {
      final list = PagedList.first(first).append(
        const CursorPage(items: [], nextCursor: 'c-3', hasMore: true),
      );

      expect(list.items, [1, 2]);
      expect(list.hasMore, isFalse);
      expect(list.nextCursor, isNull);
      expect(list.canLoadMore, isFalse);
    });

    test('a page that hands back the same cursor ends the list', () {
      final list = PagedList.first(first).append(
        const CursorPage(items: [3, 4], nextCursor: 'c-2', hasMore: true),
      );

      expect(list.items, [1, 2, 3, 4]);
      expect(list.hasMore, isFalse);
      expect(list.canLoadMore, isFalse);
    });

    test('append does not change the list it was called on', () {
      final before = PagedList.first(first);

      before.append(const CursorPage(items: [3]));

      expect(before.items, [1, 2]);
    });

    test('while a page is on its way no other may be asked for', () {
      final list = PagedList.first(first).startLoadingMore();

      expect(list.loadingMore, isTrue);
      expect(list.canLoadMore, isFalse);
      expect(list.items, [1, 2]);
    });

    test('a failed page keeps the rows and the cursor, and waits for a retry',
        () {
      final list = PagedList.first(first).startLoadingMore().failLoadingMore(
        'offline',
      );

      expect(list.items, [1, 2]);
      expect(list.nextCursor, 'c-2');
      expect(list.hasMore, isTrue);
      expect(list.loadingMore, isFalse);
      expect(list.loadMoreError, 'offline');
      expect(list.canLoadMore, isFalse);
    });

    test('starting again clears the error', () {
      final list = PagedList.first(
        first,
      ).failLoadingMore('offline').startLoadingMore();

      expect(list.loadMoreError, isNull);
      expect(list.loadingMore, isTrue);
    });

    test('an empty list has nothing to load', () {
      const list = PagedList<int>();

      expect(list.items, isEmpty);
      expect(list.canLoadMore, isFalse);
    });
  });

  group('PagedList by page number', () {
    test('the first page: its rows, and page 2 next when there are more', () {
      final list = PagedList<int>.firstNumbered(
        items: [1, 2],
        page: 1,
        totalPages: 3,
      );

      expect(list.items, [1, 2]);
      expect(list.hasMore, isTrue);
      expect(list.nextPage, 2);
      expect(list.nextCursor, isNull);
      expect(list.canLoadMore, isTrue);
      expect(list.countLabel, '2+');
    });

    test('45 rows at 20 a page: page 2, then page 3, then it stops', () {
      var list = PagedList<int>.firstNumbered(
        items: List.generate(20, (i) => i),
        page: 1,
        totalPages: 3,
      );
      list = list.appendNumbered(
        items: List.generate(20, (i) => 20 + i),
        page: 2,
        totalPages: 3,
      );
      expect(list.nextPage, 3);
      expect(list.hasMore, isTrue);

      list = list.appendNumbered(
        items: List.generate(5, (i) => 40 + i),
        page: 3,
        totalPages: 3,
      );

      expect(list.items, List.generate(45, (i) => i));
      expect(list.hasMore, isFalse);
      expect(list.nextPage, isNull);
      expect(list.canLoadMore, isFalse);
    });

    test('a single page is the whole list', () {
      final list = PagedList<int>.firstNumbered(
        items: [1],
        page: 1,
        totalPages: 1,
      );

      expect(list.hasMore, isFalse);
      expect(list.nextPage, isNull);
    });

    test('a page with no rows ends the list, whatever total_pages says', () {
      final list = PagedList<int>.firstNumbered(
        items: [1, 2],
        page: 1,
        totalPages: 5,
      ).appendNumbered(items: [], page: 2, totalPages: 5);

      expect(list.hasMore, isFalse);
    });

    test('a page number that does not move on ends the list: the same rows '
        'would come again', () {
      final list = PagedList<int>.firstNumbered(
        items: [1, 2],
        page: 1,
        totalPages: 5,
      ).appendNumbered(items: [3, 4], page: 1, totalPages: 5);

      expect(list.items, [1, 2, 3, 4]);
      expect(list.hasMore, isFalse);
    });

    test('a failed page keeps the rows and the page to ask for, and waits '
        'for a retry', () {
      final list = PagedList<int>.firstNumbered(
        items: [1, 2],
        page: 1,
        totalPages: 3,
      ).startLoadingMore();
      expect(list.loadingMore, isTrue);
      expect(list.nextPage, 2);
      expect(list.canLoadMore, isFalse);

      final failed = list.failLoadingMore('offline');

      expect(failed.items, [1, 2]);
      expect(failed.nextPage, 2);
      expect(failed.loadMoreError, 'offline');
      expect(failed.canLoadMore, isFalse);
      expect(failed.retryable.canLoadMore, isTrue);
      expect(failed.retryable.nextPage, 2);
    });

    test('with keyOf, a row already in the list is not shown twice, and the '
        'list still goes on', () {
      final list = PagedList<int>.firstNumbered(
        items: [5, 4],
        page: 1,
        totalPages: 3,
        keyOf: (i) => i,
      ).appendNumbered(items: [4, 3], page: 2, totalPages: 3, keyOf: (i) => i);

      expect(list.items, [5, 4, 3]);
      expect(list.nextPage, 3);
    });

    test('a page made only of rows already shown still moves on', () {
      final list = PagedList<int>.firstNumbered(
        items: [5, 4],
        page: 1,
        totalPages: 3,
        keyOf: (i) => i,
      ).appendNumbered(items: [4], page: 2, totalPages: 3, keyOf: (i) => i);

      expect(list.items, [5, 4]);
      expect(list.hasMore, isTrue);
    });

    test('a cursor page appended to a cursor list leaves no page number', () {
      final list = PagedList.first(
        const CursorPage(items: [1], nextCursor: 'a', hasMore: true),
      );

      expect(list.nextPage, isNull);
      expect(list.nextCursor, 'a');
    });
  });
}
