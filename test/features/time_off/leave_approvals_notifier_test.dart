import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/time_off/domain/entities/leave_request.dart';
import 'package:next_on/core/network/paged_list.dart';
import 'package:next_on/features/time_off/domain/entities/leave_status.dart';
import 'package:next_on/features/time_off/presentation/providers/leave_approvals_notifier.dart';
import 'package:next_on/features/time_off/presentation/providers/leave_approvals_state.dart';
import 'package:next_on/features/time_off/time_off_providers.dart';

import '../../support/leave_test_doubles.dart';

void main() {
  late FakeLeaveRepository repository;
  late ProviderContainer container;
  late bool started;

  final waiting = sampleLeaveRequest(id: 'req-waiting');
  final approved = sampleLeaveRequest(
    id: 'req-approved',
    status: LeaveStatus.approved,
  );
  final rejected = sampleLeaveRequest(
    id: 'req-rejected',
    status: LeaveStatus.rejected,
  );
  final cancelled = sampleLeaveRequest(
    id: 'req-cancelled',
    status: LeaveStatus.cancelled,
  );

  setUp(() {
    started = false;
    repository = FakeLeaveRepository()
      ..pendingApprovalsResult = Result.success([waiting])
      ..approvedByMeResult = Result.success([approved])
      ..rejectedByMeResult = Result.success([rejected]);
    container = ProviderContainer(
      overrides: [
        leaveRepositoryProvider.overrideWithValue(repository),
        leaveOwnEmployeeIdProvider.overrideWithValue('emp-me'),
      ],
    );
    addTearDown(container.dispose);
  });

  /// Creates the notifier, which starts its first load on a microtask, and
  /// keeps the auto-dispose provider alive for the test. Called after a test
  /// has set up what the repository answers.
  void start() {
    started = true;
    container.listen(leaveApprovalsNotifierProvider, (_, _) {});
  }

  LeaveApprovalsState state() => container.read(leaveApprovalsNotifierProvider);

  LeaveApprovalsNotifier notifier() =>
      container.read(leaveApprovalsNotifierProvider.notifier);

  /// Starts the notifier if it is not running yet, then lets its load run to
  /// the end.
  Future<void> settle() async {
    if (!started) start();
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  List<LeaveRequest> pendingRows() => state().pending.requireValue.items;
  List<LeaveRequest> decidedRows() => state().decided.requireValue.items;

  group('loading', () {
    test('starts with both lists loading, on "I approved"', () {
      start();

      expect(state().pending.isLoading, isTrue);
      expect(state().decided.isLoading, isTrue);
      expect(state().decidedFilter, LeaveDecidedFilter.approved);
      expect(state().decidingIds, isEmpty);
    });

    test('asks for what waits for me and for what I approved', () async {
      await settle();

      expect(repository.myApprovalsCalls.toSet(), {
        LeaveStatus.pending,
        LeaveStatus.approved,
      });
      expect(repository.myApprovalsCalls, hasLength(2));
      expect(repository.myApprovalsCursors, [null, null]);
    });

    test('both calls start before either ends', () async {
      final answers = <LeaveStatus?, Completer<Result<CursorPage<LeaveRequest>>>>{
        LeaveStatus.pending: Completer(),
        LeaveStatus.approved: Completer(),
      };
      repository.myApprovalsPage = (status, cursor) => answers[status]!.future;

      start();
      await Future<void>.delayed(Duration.zero);

      // Neither has been answered, and both have been asked.
      expect(repository.myApprovalsCalls.toSet(), {
        LeaveStatus.pending,
        LeaveStatus.approved,
      });

      answers[LeaveStatus.approved]!.complete(
        Result.success(CursorPage.single([approved])),
      );
      await Future<void>.delayed(Duration.zero);
      // The decided list is in while the waiting one is still on its way.
      expect(decidedRows(), [approved]);
      expect(state().pending.isLoading, isTrue);

      answers[LeaveStatus.pending]!.complete(
        Result.success(CursorPage.single([waiting])),
      );
      await Future<void>.delayed(Duration.zero);
      expect(pendingRows(), [waiting]);
    });

    test('the waiting list is what the server says waits for me', () async {
      await settle();

      expect(pendingRows(), [waiting]);
    });

    test('the decided list is what the server says I approved, whatever '
        'became of the request: nothing is filtered on the phone', () async {
      // Lee approved step 1; one still waits for HR, one was cancelled since.
      repository.approvedByMeResult = Result.success([
        waiting,
        cancelled,
        approved,
      ]);

      await settle();

      expect(decidedRows(), [waiting, cancelled, approved]);
    });

    test('setDecidedFilter asks for what I rejected, and shows that list',
        () async {
      await settle();

      notifier().setDecidedFilter(LeaveDecidedFilter.rejected);
      expect(state().decided.isLoading, isTrue);
      await settle();

      expect(repository.myApprovalsCalls.last, LeaveStatus.rejected);
      expect(state().decidedFilter, LeaveDecidedFilter.rejected);
      expect(decidedRows(), [rejected]);
      // The waiting list was left alone.
      expect(
        repository.myApprovalsCalls.where((s) => s == LeaveStatus.pending),
        hasLength(1),
      );
    });

    test('choosing the chip already chosen asks nothing', () async {
      await settle();
      final calls = repository.myApprovalsCalls.length;

      notifier().setDecidedFilter(LeaveDecidedFilter.approved);
      await settle();

      expect(repository.myApprovalsCalls, hasLength(calls));
    });

    test('an answer for the chip the user has left is dropped', () async {
      final slow = Completer<Result<CursorPage<LeaveRequest>>>();
      repository.myApprovalsPage = (status, cursor) async => switch (status) {
        LeaveStatus.approved => slow.future,
        LeaveStatus.rejected => Result.success(CursorPage.single([rejected])),
        _ => Result.success(CursorPage.single([waiting])),
      };
      start();
      await Future<void>.delayed(Duration.zero);

      notifier().setDecidedFilter(LeaveDecidedFilter.rejected);
      await settle();
      slow.complete(Result.success(CursorPage.single([approved])));
      await settle();

      expect(decidedRows(), [rejected]);
    });

    test('a failed waiting load is an error; the decided list still loads',
        () async {
      const offline = Failure.network(message: 'offline');
      repository.pendingApprovalsResult = const Result.failure(offline);

      await settle();

      expect(state().pending.error, offline);
      expect(decidedRows(), [approved]);
    });

    test('a failed decided-list load is an error, not an empty list; the '
        'waiting list still shows', () async {
      const offline = Failure.network(message: 'offline');
      repository.approvedByMeResult = const Result.failure(offline);

      await settle();

      expect(state().decided.hasError, isTrue);
      expect(state().decided.error, offline);
      expect(state().decided.hasValue, isFalse);
      expect(pendingRows(), [waiting]);
    });

    test('retrying one list leaves the other, and its pages, alone',
        () async {
      await settle();
      final before = repository.myApprovalsCalls.length;

      notifier().retryDecided();
      await settle();
      expect(repository.myApprovalsCalls.sublist(before), [
        LeaveStatus.approved,
      ]);

      notifier().retryPending();
      await settle();
      expect(repository.myApprovalsCalls.sublist(before + 1), [
        LeaveStatus.pending,
      ]);
    });

    test('retry loads both lists again, from their first pages', () async {
      await settle();

      notifier().retry();
      await settle();

      expect(repository.myApprovalsCalls, hasLength(4));
      expect(repository.myApprovalsCursors, everyElement(isNull));
    });
  });

  group('my own request', () {
    ProviderContainer signedInAs(String? employeeId) {
      final c = ProviderContainer(
        overrides: [
          leaveRepositoryProvider.overrideWithValue(repository),
          leaveOwnEmployeeIdProvider.overrideWithValue(employeeId),
        ],
      );
      addTearDown(c.dispose);
      c.listen(leaveApprovalsNotifierProvider, (_, _) {});
      return c;
    }

    final mine = sampleLeaveRequest(id: 'req-mine', employeeId: 'emp-mai');
    final someoneElses = sampleLeaveRequest(id: 'req-bee', employeeId: 'emp-bee');
    final noRequester = sampleLeaveRequest(id: 'req-x');

    test('is the one whose requester is me', () {
      final state = signedInAs('emp-mai').read(leaveApprovalsNotifierProvider);

      expect(state.ownEmployeeId, 'emp-mai');
      expect(state.isOwn(mine), isTrue);
      expect(state.isOwn(someoneElses), isFalse);
      expect(state.isOwn(noRequester), isFalse);
    });

    test('with my own id unknown, no request counts as mine', () {
      final state = signedInAs(null).read(leaveApprovalsNotifierProvider);

      expect(state.isOwn(mine), isFalse);
      // Two unknowns are not a match.
      expect(state.isOwn(noRequester), isFalse);
    });
  });

  group('loading more', () {
    List<LeaveRequest> rows(String list, int from, int count) => [
      for (var i = from; i < from + count; i++)
        sampleLeaveRequest(id: '$list-$i'),
    ];

    /// Each list has two pages: 20 rows, then 5.
    FutureResult<CursorPage<LeaveRequest>> twoPages(
      LeaveStatus? status,
      String? cursor,
    ) async {
      final list = status!.name;
      return Result.success(
        cursor == null
            ? CursorPage(
                items: rows(list, 0, 20),
                nextCursor: '$list-2',
                hasMore: true,
              )
            : CursorPage(items: rows(list, 20, 5)),
      );
    }

    setUp(() => repository.myApprovalsPage = twoPages);

    test('the waiting list: loads the next page under its rows, and leaves '
        'the decided list alone', () async {
      await settle();
      expect(pendingRows(), hasLength(20));
      expect(state().pending.requireValue.countLabel, '20+');

      await notifier().loadMorePending();

      expect(repository.myApprovalsCalls.last, LeaveStatus.pending);
      expect(repository.myApprovalsCursors.last, 'pending-2');
      expect(pendingRows().map((r) => r.id).toSet(), hasLength(25));
      expect(state().pending.requireValue.countLabel, '25');
      expect(decidedRows(), hasLength(20));
    });

    test('the decided list: loads the next page of the chip that is on',
        () async {
      await settle();
      notifier().setDecidedFilter(LeaveDecidedFilter.rejected);
      await settle();

      await notifier().loadMoreDecided();

      expect(repository.myApprovalsCalls.last, LeaveStatus.rejected);
      expect(repository.myApprovalsCursors.last, 'rejected-2');
      expect(decidedRows(), hasLength(25));
      expect(pendingRows(), hasLength(20));
    });

    test('one page at a time, and nothing at the end', () async {
      await settle();

      final first = notifier().loadMorePending();
      final second = notifier().loadMorePending();
      await Future.wait([first, second]);
      final calls = repository.myApprovalsCalls.length;
      await notifier().loadMorePending();

      expect(repository.myApprovalsCalls, hasLength(calls));
      expect(pendingRows(), hasLength(25));
    });

    test('a page asked for before a decision reloaded the lists is dropped',
        () async {
      final late = Completer<Result<CursorPage<LeaveRequest>>>();
      repository.myApprovalsPage = (status, cursor) =>
          cursor == 'pending-2' ? late.future : twoPages(status, cursor);
      await settle();

      final more = notifier().loadMorePending();
      await notifier().approve(pendingRows().first);
      late.complete(Result.success(CursorPage(items: rows('late', 0, 5))));
      await more;

      expect(pendingRows(), hasLength(20));
      expect(pendingRows().any((r) => r.id.startsWith('late')), isFalse);
      expect(state().pending.requireValue.loadingMore, isFalse);
    });

    test('a later page that fails keeps the rows; Retry asks for it again',
        () async {
      var down = true;
      repository.myApprovalsPage = (status, cursor) async =>
          cursor != null && down
          ? const Result.failure(Failure.network(message: 'offline'))
          : twoPages(status, cursor);
      await settle();

      await notifier().loadMoreDecided();
      expect(decidedRows(), hasLength(20));
      expect(state().decided.requireValue.loadMoreError, isNotNull);
      expect(state().decided.hasError, isFalse);

      // Nothing is asked again until Retry.
      final calls = repository.myApprovalsCalls.length;
      await notifier().loadMoreDecided();
      expect(repository.myApprovalsCalls, hasLength(calls));

      down = false;
      await notifier().retryLoadMoreDecided();
      expect(decidedRows(), hasLength(25));
      expect(state().decided.requireValue.loadMoreError, isNull);
    });

    test('a decision reloads both lists from page 1', () async {
      await settle();
      await notifier().loadMorePending();
      await notifier().loadMoreDecided();
      final before = repository.myApprovalsCalls.length;

      await notifier().approve(pendingRows().first);

      expect(repository.myApprovalsCalls, hasLength(before + 2));
      expect(
        repository.myApprovalsCursors.sublist(before),
        everyElement(isNull),
      );
      expect(pendingRows(), hasLength(20));
      expect(decidedRows(), hasLength(20));
    });
  });

  group('approve', () {
    test('sends the request id and the id of the step that is pending',
        () async {
      await settle();

      await notifier().approve(waiting);

      expect(repository.approveCalls.single, (
        id: 'req-waiting',
        stepId: 'step-1',
        note: null,
      ));
    });

    test('success reloads both lists and returns success', () async {
      await settle();

      final outcome = await notifier().approve(waiting);

      expect(outcome.kind, LeaveDecisionKind.success);
      expect(outcome.failure, isNull);
      expect(repository.myApprovalsCalls, hasLength(4));
      expect(state().decidingIds, isEmpty);
    });

    test('two taps on the same request send one decision; the second says '
        'nothing', () async {
      await settle();

      final first = notifier().approve(waiting);
      final second = notifier().approve(waiting);
      final outcomes = await Future.wait([first, second]);

      expect(repository.approveCalls, hasLength(1));
      expect(outcomes[0].kind, LeaveDecisionKind.success);
      expect(outcomes[1].abandoned, isTrue);
      expect(state().decidingIds, isEmpty);
    });

    test('marks the request as deciding while the call is in flight',
        () async {
      await settle();

      final pending = notifier().approve(waiting);

      expect(state().decidingIds, {'req-waiting'});
      await pending;
      expect(state().decidingIds, isEmpty);
    });

    for (final token in const [
      'leaveStepChanged',
      'leaveChanged',
      'leaveInvalidStatus',
      'leaveNotApprover',
      'leaveRequestGone',
    ]) {
      test('$token reloads both lists first and reports reloaded, with the '
          'refusal', () async {
        final failure = Failure.validation(message: token);
        repository.approveResult = Result.failure(failure);
        await settle();
        final before = repository.myApprovalsCalls.length;

        final outcome = await notifier().approve(waiting);

        expect(outcome.kind, LeaveDecisionKind.reloaded);
        expect(outcome.failure, failure);
        expect(repository.myApprovalsCalls, hasLength(before + 2));
        expect(state().decidingIds, isEmpty);
      });
    }

    test('the reload is done by the time the outcome is reported: the card '
        'is already gone', () async {
      repository.approveResult = const Result.failure(
        Failure.validation(message: 'leaveInvalidStatus'),
      );
      await settle();
      // The employee cancelled it meanwhile.
      repository.pendingApprovalsResult = const Result.success([]);

      await notifier().approve(waiting);

      expect(state().pending.valueOrNull!.items, isEmpty);
    });

    test('a refusal with a code the App does not know reports failed with '
        'the server\'s message, and does not reload', () async {
      const refusal = Failure.validation(
        message: 'A leave request can run at most 1 year',
        code: 'LEAVE_SPAN_TOO_LONG',
      );
      repository.approveResult = const Result.failure(refusal);
      await settle();
      final before = repository.myApprovalsCalls.length;

      final outcome = await notifier().approve(waiting);

      expect(outcome.kind, LeaveDecisionKind.failed);
      expect(outcome.failure, refusal);
      expect(repository.myApprovalsCalls, hasLength(before));
    });

    test('no signal or a server error reports failed with the failure, and '
        'does not reload', () async {
      for (final failure in const [
        Failure.network(message: 'offline'),
        Failure.server(message: 'boom', statusCode: 500),
        // A leave token that says nothing about this request being stale.
        Failure.validation(message: 'leaveEmployeeNotFound'),
      ]) {
        repository.approveResult = Result.failure(failure);
        await settle();
        final before = repository.myApprovalsCalls.length;

        final outcome = await notifier().approve(waiting);

        expect(outcome.kind, LeaveDecisionKind.failed, reason: '$failure');
        expect(outcome.failure, failure);
        expect(repository.myApprovalsCalls, hasLength(before));
        expect(state().decidingIds, isEmpty);
      }
    });
  });

  group('reject', () {
    test('sends the reason and the id of the step that is pending', () async {
      await settle();

      await notifier().reject(waiting, 'No cover that week');

      expect(repository.rejectCalls.single, (
        id: 'req-waiting',
        reason: 'No cover that week',
        stepId: 'step-1',
        note: null,
      ));
    });

    test('success reloads; a stale refusal reloads and says so; anything '
        'else fails', () async {
      await settle();
      expect(
        (await notifier().reject(waiting, 'no')).kind,
        LeaveDecisionKind.success,
      );

      repository.rejectResult = const Result.failure(
        Failure.validation(message: 'leaveChanged'),
      );
      final before = repository.myApprovalsCalls.length;
      expect(
        (await notifier().reject(waiting, 'no')).kind,
        LeaveDecisionKind.reloaded,
      );
      expect(repository.myApprovalsCalls, hasLength(before + 2));

      repository.rejectResult = const Result.failure(
        Failure.network(message: 'offline'),
      );
      expect(
        (await notifier().reject(waiting, 'no')).kind,
        LeaveDecisionKind.failed,
      );
    });
  });

  test('a request with no pending step is decided with no step id', () async {
    await settle();

    await notifier().approve(sampleLeaveRequest(id: 'req-x', steps: const []));

    expect(repository.approveCalls.single.stepId, isNull);
  });
}
