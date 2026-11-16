import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/utils/result.dart';
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
      ..allApprovalsResult = Result.success([
        waiting,
        approved,
        rejected,
        cancelled,
      ]);
    container = ProviderContainer(
      overrides: [leaveRepositoryProvider.overrideWithValue(repository)],
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

  group('loading', () {
    test('starts with both lists loading', () {
      start();

      expect(state().pending.isLoading, isTrue);
      expect(state().history.isLoading, isTrue);
      expect(state().decidingIds, isEmpty);
    });

    test('asks for the pending list, then for everything', () async {
      await settle();

      expect(repository.myApprovalsCalls, [LeaveStatus.pending, null]);
    });

    test('the pending list is what the server calls pending', () async {
      await settle();

      expect(state().pending.requireValue, [waiting]);
    });

    test('the decided list keeps only approved and rejected requests',
        () async {
      await settle();

      expect(state().history.requireValue, [approved, rejected]);
    });

    test('a failed pending load is an error; the decided list still loads',
        () async {
      const offline = Failure.network(message: 'offline');
      repository.pendingApprovalsResult = const Result.failure(offline);

      await settle();

      expect(state().pending.error, offline);
      expect(state().history.requireValue, [approved, rejected]);
    });

    test('a failed decided-list load is an error, not an empty list; the '
        'pending list still shows', () async {
      const offline = Failure.network(message: 'offline');
      repository.allApprovalsResult = const Result.failure(offline);

      await settle();

      expect(state().history.hasError, isTrue);
      expect(state().history.error, offline);
      expect(state().history.hasValue, isFalse);
      expect(state().pending.requireValue, [waiting]);
    });

    test('retry loads both lists again', () async {
      await settle();

      notifier().retry();
      await settle();

      expect(repository.myApprovalsCalls, [
        LeaveStatus.pending,
        null,
        LeaveStatus.pending,
        null,
      ]);
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

      expect(state().pending.valueOrNull, isEmpty);
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
