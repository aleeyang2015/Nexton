import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/network/paged_list.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/attendance/attendance_providers.dart';
import 'package:next_on/features/attendance/data/datasources/offsite_error_code.dart';
import 'package:next_on/features/attendance/domain/entities/offsite_detail.dart';
import 'package:next_on/features/attendance/domain/entities/time_correction_status.dart';
import 'package:next_on/features/attendance/presentation/providers/offsite_approvals_notifier.dart';
import 'package:next_on/features/attendance/presentation/providers/offsite_decision_notifier.dart';
import 'package:next_on/features/auth/domain/entities/user.dart';
import 'package:next_on/features/auth/presentation/providers/auth_session_notifier.dart';
import 'package:next_on/features/time_off/data/datasources/leave_error_code.dart';

import '../../support/approver_access_test_doubles.dart';
import '../../support/attendance_test_doubles.dart';
import '../../support/offsite_approval_test_doubles.dart';

/// The approvals page's off-site lists and the decisions on them (#46).
void main() {
  late FakeOffsiteRepository repository;
  late ProviderContainer container;

  final hr = approverTestUser(
    head: false,
    permissions: const ['corehr:attendanceRecord:manage'],
    employeeId: 'e-hr',
  );

  CursorPage<OffsiteRequestDetail> page(
    List<OffsiteRequestDetail> rows, {
    String? next,
  }) => CursorPage(items: rows, nextCursor: next, hasMore: next != null);

  Future<void> start({User? user}) async {
    container = ProviderContainer(
      overrides: [
        offsiteRepositoryProvider.overrideWithValue(repository),
        signedInAs(user ?? hr),
      ],
    );
    addTearDown(container.dispose);
    // Signed in, as the App always is by the time the Approvals place opens.
    await container.read(authSessionProvider.future);
    final sub = container.listen(offsiteApprovalsNotifierProvider, (_, _) {});
    addTearDown(sub.close);
    await pumpEventQueue();
  }

  OffsiteApprovalsNotifier lists() =>
      container.read(offsiteApprovalsNotifierProvider.notifier);

  OffsiteDecisionNotifier decision(String id) {
    final provider = offsiteDecisionNotifierProvider(id);
    final sub = container.listen(provider, (_, _) {});
    addTearDown(sub.close);
    return container.read(provider.notifier);
  }

  int callsFor(TimeCorrectionStatus status) =>
      repository.approvalsCalls.where((c) => c.status == status).length;

  setUp(() {
    repository = FakeOffsiteRepository()
      ..approvalsPages = {
        TimeCorrectionStatus.pending: [
          Result.success(page([offsiteForApproval()], next: 'c1')),
          Result.success(page([offsiteForApproval(id: 'o-2')])),
        ],
        TimeCorrectionStatus.approved: [
          Result.success(
            page([offsiteForApproval(id: 'o-9', status: TimeCorrectionStatus.approved)]),
          ),
        ],
        TimeCorrectionStatus.rejected: [Result.success(page([]))],
      };
  });

  group('the lists', () {
    test('waiting (status=pending) and "I approved" (status=approved) load '
        'together; "I rejected" asks for status=rejected', () async {
      await start();

      expect(repository.approvalsCalls, unorderedEquals([
        (status: TimeCorrectionStatus.pending, cursor: null),
        (status: TimeCorrectionStatus.approved, cursor: null),
      ]));
      final state = container.read(offsiteApprovalsNotifierProvider);
      expect(state.pending.value!.items.single.id, 'o-1');
      expect(state.decided.value!.items.single.id, 'o-9');

      lists().selectDecided(TimeCorrectionStatus.rejected);
      await pumpEventQueue();
      expect(repository.approvalsCalls.last, (
        status: TimeCorrectionStatus.rejected,
        cursor: null,
      ));
    });

    test('the next waiting page is asked for with the cursor, once', () async {
      await start();

      await Future.wait([lists().loadMorePending(), lists().loadMorePending()]);
      await lists().loadMorePending();

      expect(repository.approvalsCalls.last, (
        status: TimeCorrectionStatus.pending,
        cursor: 'c1',
      ));
      expect(callsFor(TimeCorrectionStatus.pending), 2);
      expect(
        container
            .read(offsiteApprovalsNotifierProvider)
            .pending
            .value!
            .items
            .map((r) => r.id),
        ['o-1', 'o-2'],
      );
    });
  });

  group('decisions', () {
    test('approve sends the waiting step\'s id and the note, then reads the '
        'lists again', () async {
      await start();
      final before = repository.approvalsCalls.length;

      final result = await decision('o-1').approve(
        offsiteForApproval(),
        note: ' fine ',
      );

      expect(result!.isSuccess, isTrue);
      expect(repository.approved, [(id: 'o-1', stepId: 'step-1', note: 'fine')]);
      expect(repository.approvalsCalls.length, before + 2);
    });

    test('a blank note is sent as none', () async {
      await start();
      await decision('o-1').approve(offsiteForApproval(), note: '   ');
      expect(repository.approved.single.note, isNull);
    });

    test('reject sends the reason and the waiting step', () async {
      await start();
      await decision('o-1').reject(offsiteForApproval(), 'Not at a client');
      expect(repository.rejected, [
        (id: 'o-1', note: 'Not at a client', stepId: 'step-1'),
      ]);
    });

    test('NOT_PENDING (decided by someone else): said, and the lists are '
        'read again, so the row goes', () async {
      await start();
      repository.decisionResult = const Result.failure(
        Failure.validation(
          message: OffsiteErrorCode.tokenAlreadyDecided,
          code: 'NOT_PENDING',
        ),
      );
      final before = callsFor(TimeCorrectionStatus.pending);

      final result = await decision('o-1').approve(offsiteForApproval());

      expect(result!.isFailure, isTrue);
      expect(callsFor(TimeCorrectionStatus.pending), before + 1);
    });

    test('STEP_CHANGED reads the lists again too', () async {
      await start();
      repository.decisionResult = const Result.failure(
        Failure.validation(message: LeaveErrorCode.tokenStepChanged),
      );
      final before = callsFor(TimeCorrectionStatus.pending);

      await decision('o-1').approve(offsiteForApproval());

      expect(callsFor(TimeCorrectionStatus.pending), before + 1);
    });

    for (final (code, token) in [
      ('TOO_EARLY_CHECKIN', OffsiteErrorCode.tokenTooEarlyCheckin),
      ('CHECKIN_PENDING_APPROVAL', OffsiteErrorCode.tokenApproveCheckinFirst),
    ]) {
      test('$code: the request stays waiting, so the row stays', () async {
        await start();
        repository.decisionResult = Result.failure(
          Failure.validation(message: token, code: code),
        );
        final before = repository.approvalsCalls.length;

        final result = await decision('o-1').approve(offsiteForApproval());

        expect(result!.failureOrNull, isNotNull);
        expect(repository.approvalsCalls.length, before);
        expect(
          container.read(offsiteApprovalsNotifierProvider).pending.value!.items,
          hasLength(1),
        );
      });
    }

    test('CHECKIN_NOT_APPROVED: the row can only be rejected now', () async {
      await start();
      repository.decisionResult = const Result.failure(
        Failure.validation(
          message: OffsiteErrorCode.tokenCheckinNotApproved,
          code: 'CHECKIN_NOT_APPROVED',
        ),
      );

      await decision('o-1').approve(offsiteForApproval());

      expect(
        container.read(offsiteApprovalsNotifierProvider).rejectOnlyIds,
        {'o-1'},
      );
    });

    test('NOT_APPROVER on the approver\'s own request says "your own"; on '
        'someone else\'s, "another approver"', () async {
      await start();
      repository.decisionResult = const Result.failure(
        Failure.validation(
          message: OffsiteErrorCode.tokenAnotherApprover,
          code: 'NOT_APPROVER',
        ),
      );

      final own = await decision('o-own').approve(
        offsiteForApproval(id: 'o-own', employeeId: 'e-hr'),
      );
      final other = await decision('o-1').approve(offsiteForApproval());

      expect(
        (own!.failureOrNull! as ValidationFailure).message,
        OffsiteErrorCode.tokenCannotDecideOwn,
      );
      expect(
        (other!.failureOrNull! as ValidationFailure).message,
        OffsiteErrorCode.tokenAnotherApprover,
      );
    });

    test('a double tap sends once; the second tells nothing', () async {
      await start();
      final hold = Completer<void>();
      repository.holdDecision = hold;
      final notifier = decision('o-1');

      final first = notifier.approve(offsiteForApproval());
      final second = await notifier.approve(offsiteForApproval());
      expect(container.read(offsiteDecisionNotifierProvider('o-1')), isTrue);
      hold.complete();
      await first;

      expect(second, isNull);
      expect(repository.approved, hasLength(1));
      expect(container.read(offsiteDecisionNotifierProvider('o-1')), isFalse);
    });
  });
}
