import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/network/paged_list.dart';

void main() {
  int id(Map<String, dynamic> json) => json['id'] as int;

  Map<String, dynamic> body(List<int> ids, {Map<String, dynamic>? meta}) => {
    'success': true,
    'data': [
      for (final i in ids) {'id': i},
    ],
    'meta': ?meta,
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
}
