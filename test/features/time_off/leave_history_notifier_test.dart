import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/time_off/domain/entities/leave_request.dart';
import 'package:next_on/features/time_off/domain/entities/leave_history_query.dart';
import 'package:next_on/core/network/paged_list.dart';
import 'package:next_on/features/time_off/domain/entities/leave_status.dart';
import 'package:next_on/features/time_off/presentation/providers/leave_history_notifier.dart';
import 'package:next_on/features/time_off/presentation/providers/leave_history_state.dart';
import 'package:next_on/features/time_off/time_off_providers.dart';

import '../../support/leave_test_doubles.dart';

void main() {
  late FakeLeaveRepository repository;
  late ProviderContainer container;

  final pending = sampleLeaveRequest(id: 'req-1');

  setUp(() {
    repository = FakeLeaveRepository()
      ..myRequestsResult = Result.success([pending]);
    container = ProviderContainer(
      overrides: [leaveRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  LeaveHistoryState state() => container.read(leaveHistoryNotifierProvider);

  LeaveHistoryNotifier notifier() =>
      container.read(leaveHistoryNotifierProvider.notifier);

  /// Starts the notifier, keeps it alive, and lets its first load finish.
  Future<void> settle() async {
    container.listen(leaveHistoryNotifierProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  group('cancel', () {
    test('success returns the request and reloads the list', () async {
      await settle();
      final before = repository.myRequestsCalls.length;

      final result = await notifier().cancel('req-1');

      expect(result.isSuccess, isTrue);
      expect(repository.cancelCalls, ['req-1']);
      expect(repository.myRequestsCalls, hasLength(before + 1));
      expect(state().cancellingIds, isEmpty);
    });

    test('marks the request as cancelling while the call is in flight',
        () async {
      await settle();

      final call = notifier().cancel('req-1');

      expect(state().cancellingIds, {'req-1'});
      await call;
      expect(state().cancellingIds, isEmpty);
    });

    for (final token in const [
      'leaveChanged',
      'leaveInvalidStatus',
      'leaveRequestGone',
    ]) {
      test('$token returns the failure and reloads the list, so it shows the '
          'request as it now is', () async {
        final failure = Failure.validation(message: token);
        repository.cancelResult = Result.failure(failure);
        await settle();
        final before = repository.myRequestsCalls.length;
        // HR approved it meanwhile.
        repository.myRequestsResult = Result.success([
          sampleLeaveRequest(id: 'req-1', status: LeaveStatus.approved),
        ]);

        final result = await notifier().cancel('req-1');

        expect(result.failureOrNull, failure);
        expect(repository.myRequestsCalls, hasLength(before + 1));
        expect(
          state().requests.valueOrNull!.items.single.status,
          LeaveStatus.approved,
        );
        expect(state().cancellingIds, isEmpty);
      });
    }

    test('the request stays marked as cancelling until the reload is back, '
        'so Cancel cannot be tapped twice', () async {
      repository.cancelResult = const Result.failure(
        Failure.validation(message: 'leaveChanged'),
      );
      await settle();
      final marks = <bool>[];
      container.listen(leaveHistoryNotifierProvider, (_, next) {
        if (next.requests.isLoading) {
          marks.add(next.cancellingIds.contains('req-1'));
        }
      });

      await notifier().cancel('req-1');

      expect(marks, isNotEmpty);
      expect(marks, everyElement(isTrue));
      expect(state().cancellingIds, isEmpty);
    });

    test('any other failure returns the failure and leaves the list alone',
        () async {
      for (final failure in const [
        Failure.network(message: 'offline'),
        Failure.server(message: 'boom', statusCode: 500),
        Failure.validation(message: 'Not allowed', code: 'SOMETHING_NEW'),
        Failure.validation(message: 'leaveNotApprover'),
      ]) {
        repository.cancelResult = Result.failure(failure);
        await settle();
        final before = repository.myRequestsCalls.length;

        final result = await notifier().cancel('req-1');

        expect(result.failureOrNull, failure, reason: '$failure');
        expect(repository.myRequestsCalls, hasLength(before));
        expect(state().cancellingIds, isEmpty);
      }
    });
  });

  group('loading more', () {
    List<LeaveRequest> rows(int from, int count) => [
      for (var i = from; i < from + count; i++) sampleLeaveRequest(id: 'r-$i'),
    ];

    /// Three pages: 20, 20 and 5 rows, linked by the cursors `c-2`, `c-3`.
    FutureResult<CursorPage<LeaveRequest>> threePages(
      LeaveHistoryQuery query,
      String? cursor,
    ) async => Result.success(switch (cursor) {
      null => CursorPage(items: rows(0, 20), nextCursor: 'c-2', hasMore: true),
      'c-2' => CursorPage(
        items: rows(20, 20),
        nextCursor: 'c-3',
        hasMore: true,
      ),
      _ => CursorPage(items: rows(40, 5)),
    });

    List<String> ids() => [
      for (final r in state().requests.valueOrNull!.items) r.id,
    ];

    test('the first page is asked for with no cursor and shows its rows',
        () async {
      repository.myRequestsPage = threePages;
      await settle();

      expect(repository.myRequestsCursors, [null]);
      expect(ids(), hasLength(20));
      expect(state().requests.valueOrNull!.hasMore, isTrue);
    });

    test('loadMore adds the next page under the rows, in order, until the '
        'end; no request shows twice', () async {
      repository.myRequestsPage = threePages;
      await settle();

      await notifier().loadMore();
      expect(ids(), hasLength(40));
      await notifier().loadMore();

      expect(repository.myRequestsCursors, [null, 'c-2', 'c-3']);
      expect(ids(), [for (var i = 0; i < 45; i++) 'r-$i']);
      expect(ids().toSet(), hasLength(45));
      expect(state().requests.valueOrNull!.hasMore, isFalse);
    });

    test('at the end loadMore does nothing', () async {
      repository.myRequestsPage = threePages;
      await settle();
      await notifier().loadMore();
      await notifier().loadMore();
      final calls = repository.myRequestsCalls.length;

      await notifier().loadMore();

      expect(repository.myRequestsCalls, hasLength(calls));
    });

    test('a later page keeps the filter and range of the first', () async {
      repository.myRequestsPage = threePages;
      await settle();
      notifier().filterByLeaveType('lt-sick');
      await Future<void>.delayed(Duration.zero);

      await notifier().loadMore();

      expect(repository.myRequestsCalls.last.leaveTypeId, 'lt-sick');
      expect(repository.myRequestsCalls.last, repository.myRequestsCalls[1]);
    });

    test('a second call while a page is loading does nothing', () async {
      repository.myRequestsPage = threePages;
      await settle();

      final first = notifier().loadMore();
      expect(state().requests.valueOrNull!.loadingMore, isTrue);
      final second = notifier().loadMore();
      await Future.wait([first, second]);

      expect(repository.myRequestsCursors, [null, 'c-2']);
      expect(ids(), hasLength(40));
      expect(state().requests.valueOrNull!.loadingMore, isFalse);
    });

    test('loadMore does nothing while the first page is still loading',
        () async {
      repository.myRequestsPage = threePages;
      container.listen(leaveHistoryNotifierProvider, (_, _) {});

      // Asked before the first page has even gone out.
      final early = notifier().loadMore();
      await early;
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      // Only the first page was fetched; nothing was asked for with a cursor.
      expect(repository.myRequestsCursors, [null]);
    });

    test('a page for a filter the user has left is dropped: only the new '
        'filter\'s rows show', () async {
      final late = Completer<Result<CursorPage<LeaveRequest>>>();
      repository.myRequestsPage = (query, cursor) async {
        if (cursor == 'c-2') return late.future;
        if (query.leaveTypeId == 'lt-sick') {
          return Result.success(
            CursorPage(items: [sampleLeaveRequest(id: 'sick-1')]),
          );
        }
        return threePages(query, cursor);
      };
      await settle();

      final more = notifier().loadMore();
      notifier().filterByLeaveType('lt-sick');
      await Future<void>.delayed(Duration.zero);
      late.complete(Result.success(CursorPage(items: rows(20, 20))));
      await more;

      expect(ids(), ['sick-1']);
    });

    test('a page asked for before a reload of the same filter is dropped',
        () async {
      final late = Completer<Result<CursorPage<LeaveRequest>>>();
      repository.myRequestsPage = (query, cursor) async =>
          cursor == 'c-2' ? late.future : threePages(query, cursor);
      await settle();

      final more = notifier().loadMore();
      notifier().retry();
      await Future<void>.delayed(Duration.zero);
      late.complete(Result.success(CursorPage(items: rows(20, 20))));
      await more;

      expect(ids(), hasLength(20));
      expect(state().requests.valueOrNull!.loadingMore, isFalse);
    });

    group('a later page that fails', () {
      const offline = Failure.network(message: 'offline');
      late bool down;

      setUp(() {
        down = true;
        repository.myRequestsPage = (query, cursor) async =>
            cursor == 'c-2' && down
            ? const Result.failure(offline)
            : threePages(query, cursor);
      });

      test('keeps the rows and sets the error', () async {
        await settle();

        await notifier().loadMore();

        final list = state().requests.valueOrNull!;
        expect(state().requests.hasError, isFalse);
        expect(list.items, hasLength(20));
        expect(list.loadMoreError, offline);
        expect(list.loadingMore, isFalse);
        expect(list.hasMore, isTrue);
      });

      test('is not asked for again by scrolling; only Retry does', () async {
        await settle();
        await notifier().loadMore();
        final calls = repository.myRequestsCalls.length;

        await notifier().loadMore();
        expect(repository.myRequestsCalls, hasLength(calls));

        down = false;
        await notifier().retryLoadMore();

        expect(repository.myRequestsCursors.last, 'c-2');
        expect(ids(), hasLength(40));
        expect(state().requests.valueOrNull!.loadMoreError, isNull);
      });

      test('a cursor the server refuses: Retry starts over from page 1',
          () async {
        repository.myRequestsPage = (query, cursor) async => cursor == 'c-2'
            ? const Result.failure(
                Failure.validation(
                  message: 'invalid cursor',
                  code: 'VALIDATION_ERROR',
                ),
              )
            : threePages(query, cursor);
        await settle();
        await notifier().loadMore();
        expect(state().requests.valueOrNull!.loadMoreError, isNotNull);

        await notifier().retryLoadMore();

        expect(repository.myRequestsCursors, [null, 'c-2', null]);
        expect(ids(), hasLength(20));
        expect(state().requests.valueOrNull!.loadMoreError, isNull);
      });

      test('another refusal (403, 422) is not a bad cursor: Retry asks for '
          'the same page', () async {
        repository.myRequestsPage = (query, cursor) async =>
            cursor == 'c-2' && down
            ? const Result.failure(
                Failure.validation(message: 'Not allowed', code: 'FORBIDDEN'),
              )
            : threePages(query, cursor);
        await settle();
        await notifier().loadMore();

        down = false;
        await notifier().retryLoadMore();

        expect(repository.myRequestsCursors, [null, 'c-2', 'c-2']);
        expect(ids(), hasLength(40));
      });

      test('Retry with nothing failed does nothing', () async {
        await settle();
        final calls = repository.myRequestsCalls.length;

        await notifier().retryLoadMore();

        expect(repository.myRequestsCalls, hasLength(calls));
      });
    });

    test('a cancel reloads from page 1', () async {
      repository.myRequestsPage = threePages;
      await settle();
      await notifier().loadMore();

      await notifier().cancel('r-0');

      expect(repository.myRequestsCursors.last, isNull);
      expect(ids(), hasLength(20));
    });
  });
}
