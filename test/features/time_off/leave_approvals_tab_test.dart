import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/network/paged_list.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/core/widgets/app_toast.dart';
import 'package:next_on/features/time_off/domain/entities/leave_approval_step.dart';
import 'package:next_on/features/time_off/domain/entities/leave_request.dart';
import 'package:next_on/features/time_off/domain/entities/leave_status.dart';
import 'package:next_on/features/time_off/presentation/providers/leave_approvals_notifier.dart';
import 'package:next_on/features/time_off/presentation/widgets/leave_approvals_tab.dart';
import 'package:next_on/features/time_off/time_off_providers.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';
import 'package:next_on/l10n/generated/app_localizations_en.dart';
import 'package:next_on/l10n/generated/app_localizations_lo.dart';

import '../../support/leave_test_doubles.dart';

/// What the approvals tab tells a department head when a decision is
/// refused, and what is left on screen afterwards.
void main() {
  final en = AppLocalizationsEn();
  late FakeLeaveRepository repository;

  setUp(() {
    repository = FakeLeaveRepository()
      ..pendingApprovalsResult = Result.success([pendingApproval()]);
  });

  Future<void> pumpTab(
    WidgetTester tester, {
    String locale = 'en',
    String? signedInAs = 'emp-me',
    double height = 1200,
  }) async {
    tester.view.physicalSize = Size(390, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          leaveRepositoryProvider.overrideWithValue(repository),
          leaveOwnEmployeeIdProvider.overrideWithValue(signedInAs),
        ],
        child: MaterialApp(
          // Toasts are raised through this key, as in the App.
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale(locale),
          home: const Scaffold(body: LeaveApprovalsTab()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  /// Approve asks first (#37): confirms the dialog, with no note.
  Future<void> confirmApprove(
    WidgetTester tester, [
    String approveLabel = 'Approve',
  ]) async {
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(approveLabel),
      ),
    );
    // The dialog's closing animation.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// Taps Approve with the server set to answer [failure], and lets the
  /// reload and the toast land.
  Future<void> approveRefusedWith(
    WidgetTester tester,
    Failure failure, {
    String approveLabel = 'Approve',
  }) async {
    repository.approveResult = Result.failure(failure);
    await tester.tap(find.text(approveLabel));
    await confirmApprove(tester, approveLabel);
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }


  testWidgets('the employee cancelled it meanwhile: "no longer waiting", and '
      'the card is gone', (tester) async {
    await pumpTab(tester);
    expect(find.text('Approve'), findsOneWidget);

    // The reload after the refusal no longer has it.
    repository.pendingApprovalsResult = const Result.success([]);
    await approveRefusedWith(
      tester,
      const Failure.validation(message: 'leaveInvalidStatus'),
    );

    expect(find.text(en.leaveApprovalNoLongerWaiting), findsOneWidget);
    // Not the wording an owner gets on an edit.
    expect(find.text(en.leaveInvalidStatus), findsNothing);
    expect(find.text('Approve'), findsNothing);
  });

  final reloadedText = {
    'leaveStepChanged': en.leaveStepChanged,
    'leaveChanged': en.leaveChanged,
    'leaveNotApprover': en.leaveNotApprover,
    'leaveRequestGone': en.leaveRequestGone,
  };

  for (final MapEntry(key: token, value: text) in reloadedText.entries) {
    testWidgets('$token shows its own text and reloads the lists', (
      tester,
    ) async {
      await pumpTab(tester);
      final before = repository.myApprovalsCalls.length;

      await approveRefusedWith(tester, Failure.validation(message: token));

      expect(find.text(text), findsOneWidget);
      expect(find.text(en.leaveApprovalDecideFailed), findsNothing);
      expect(repository.myApprovalsCalls, hasLength(before + 2));
    });
  }

  testWidgets('a refusal with a code the App does not know shows the '
      'server\'s message, not "could not decide", and the card stays', (
    tester,
  ) async {
    await pumpTab(tester);
    final before = repository.myApprovalsCalls.length;

    await approveRefusedWith(
      tester,
      const Failure.validation(
        message: 'A leave request can run at most 1 year',
        code: 'LEAVE_SPAN_TOO_LONG',
      ),
    );

    expect(find.text('A leave request can run at most 1 year'), findsOneWidget);
    expect(find.text(en.leaveApprovalDecideFailed), findsNothing);
    expect(find.text('Approve'), findsOneWidget);
    expect(repository.myApprovalsCalls, hasLength(before));
  });

  testWidgets('not enough days left: the approver is told it is the '
      'employee\'s balance and what to do, and the card stays with its '
      'buttons (#70)', (tester) async {
    await pumpTab(tester);
    final before = repository.myApprovalsCalls.length;

    await approveRefusedWith(
      tester,
      const Failure.validation(message: 'leaveInsufficientBalance'),
    );

    expect(find.text(en.leaveApprovalInsufficientBalance), findsOneWidget);
    // Not the employee's own "you don't have enough", nor the general toast.
    expect(find.text(en.leaveInsufficientBalance), findsNothing);
    expect(find.text(en.leaveApprovalDecideFailed), findsNothing);
    expect(find.text('Approve'), findsOneWidget);
    expect(find.text('Reject'), findsOneWidget);
    expect(repository.myApprovalsCalls, hasLength(before));
  });

  testWidgets('no signal shows the network text, and the card stays', (
    tester,
  ) async {
    await pumpTab(tester);

    await approveRefusedWith(tester, const Failure.network(message: 'offline'));

    expect(find.text(en.leaveApprovalDecideFailed), findsNothing);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Approve'), findsOneWidget);
  });

  testWidgets('on a slow network the reason is still shown, though the '
      'reload has taken the card away by then', (tester) async {
    final slow = _SlowApprovals()
      ..pendingApprovalsResult = Result.success([pendingApproval()]);
    repository = slow;
    await pumpTab(tester);
    expect(find.text('Approve'), findsOneWidget);

    slow
      // Longer than the approve dialog's closing animation (#37).
      ..delay = const Duration(milliseconds: 1000)
      ..pendingApprovalsResult = const Result.success([])
      ..approveResult = const Result.failure(
        Failure.validation(message: 'leaveInvalidStatus'),
      );
    await tester.tap(find.text('Approve'));
    await confirmApprove(tester);
    // The refusal is in, the reload is under way: the card is gone, and
    // nothing has been said yet.
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Approve'), findsNothing);
    expect(find.text(en.leaveApprovalNoLongerWaiting), findsNothing);

    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump();

    expect(find.text(en.leaveApprovalNoLongerWaiting), findsOneWidget);
    expect(find.text('Approve'), findsNothing);
  });

  testWidgets('a decision that goes through says "Approved", and no refusal',
      (tester) async {
    await pumpTab(tester);

    await tester.tap(find.text('Approve'));
    await confirmApprove(tester);
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text(en.apprApprovedToast), findsOneWidget);
    expect(find.text(en.leaveApprovalDecideFailed), findsNothing);
    expect(find.text(en.leaveApprovalNoLongerWaiting), findsNothing);
  });

  group('Approve asks first (#37)', () {
    testWidgets('Cancel in the dialog sends nothing', (tester) async {
      await pumpTab(tester);

      await tester.tap(find.text('Approve'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(en.cancel));
      await tester.pumpAndSettle();

      expect(repository.approveCalls, isEmpty);
    });

    testWidgets('the note typed is sent as approver_note', (tester) async {
      await pumpTab(tester);

      await tester.tap(find.text('Approve'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '  ok, enjoy  ');
      await confirmApprove(tester);
      await tester.pump();

      expect(repository.approveCalls.single.note, 'ok, enjoy');
    });

    testWidgets('no note typed: none sent', (tester) async {
      await pumpTab(tester);

      await tester.tap(find.text('Approve'));
      await confirmApprove(tester);
      await tester.pump();

      expect(repository.approveCalls.single.note, isNull);
    });

    testWidgets('a reject that goes through says "Rejected"', (tester) async {
      await pumpTab(tester);

      await tester.tap(find.text('Reject'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Short-staffed');
      await tester.pump();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(en.leaveRejectReasonSubmit),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(en.apprRejectedToast), findsOneWidget);
    });
  });

  testWidgets('in Lao the refusal is in Lao', (tester) async {
    final lo = AppLocalizationsLo();
    await pumpTab(tester, locale: 'lo');

    await approveRefusedWith(
      tester,
      const Failure.validation(message: 'leaveInvalidStatus'),
      approveLabel: lo.leaveApprovalApproveAction,
    );

    expect(
      find.text('ຄຳຮ້ອງນີ້ບໍ່ໄດ້ລໍຖ້າການອະນຸມັດແລ້ວ (ມີຄົນຕັດສິນແລ້ວ ຫຼື ຖືກຍົກເລີກ).'),
      findsOneWidget,
    );
  });

  testWidgets('a reason typed while the lists reload is still sent, and '
      'the answer still said', (tester) async {
    final slow = _SlowApprovals()
      ..pendingApprovalsResult = Result.success([pendingApproval()]);
    repository = slow;
    await pumpTab(tester);

    await tester.tap(find.text('Reject'));
    await tester.pumpAndSettle();
    // Meanwhile the lists reload (another card was decided), and this card
    // is off the screen while they do.
    slow.delay = const Duration(milliseconds: 300);
    tester
        .element(find.byType(LeaveApprovalsTab))
        .let((e) => ProviderScope.containerOf(e))
        .read(leaveApprovalsNotifierProvider.notifier)
        .retry();
    await tester.pump(const Duration(milliseconds: 50));

    // The card is gone from under the dialog.
    expect(find.text('Approve'), findsNothing);

    await tester.enterText(find.byType(TextField), 'No cover that week');
    await tester.pump();
    slow.rejectResult = const Result.failure(
      Failure.validation(message: 'leaveInvalidStatus'),
    );
    await tester.tap(find.text(en.leaveRejectReasonSubmit));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();

    expect(slow.rejectCalls.single.reason, 'No cover that week');
    expect(find.text(en.leaveApprovalNoLongerWaiting), findsOneWidget);
  });

  testWidgets('Retry on a list that failed reloads that list only', (
    tester,
  ) async {
    repository.approvedByMeResult = const Result.failure(
      Failure.network(message: 'offline'),
    );
    await pumpTab(tester);
    expect(find.text(en.leaveApprovalsLoadFailed), findsOneWidget);
    final before = repository.myApprovalsCalls.length;

    repository.approvedByMeResult = const Result.success([]);
    await tester.tap(find.text(en.retry));
    await tester.pump();
    await tester.pump();

    expect(repository.myApprovalsCalls.sublist(before), [LeaveStatus.approved]);
    expect(find.text(en.leaveApprovalsLoadFailed), findsNothing);
  });

  group('my own request among those waiting', () {
    final mine = sampleLeaveRequest(
      id: 'req-mine',
      employeeId: 'emp-mai',
      employeeName: 'Mai Vongsa',
    );
    final bees = sampleLeaveRequest(
      id: 'req-bee',
      employeeId: 'emp-bee',
      employeeName: 'Bee Keo',
    );

    setUp(() {
      repository.pendingApprovalsResult = Result.success([mine, bees]);
    });

    testWidgets('has the note and no buttons; the other card keeps its '
        'buttons', (tester) async {
      await pumpTab(tester, signedInAs: 'emp-mai');

      expect(find.text(en.leaveOwnRequestNoActions), findsOneWidget);
      expect(find.text('Approve'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);

      await tester.tap(find.text('Approve'));
      await confirmApprove(tester);
      await tester.pump();
      expect(repository.approveCalls.single.id, 'req-bee');
    });

    testWidgets('with my own id unknown every card has its buttons', (
      tester,
    ) async {
      await pumpTab(tester, signedInAs: null);

      expect(find.text(en.leaveOwnRequestNoActions), findsNothing);
      expect(find.text('Approve'), findsNWidgets(2));
    });
  });

  group('the waiting count', () {
    List<LeaveRequest> rows(int from, int count) => [
      for (var i = from; i < from + count; i++)
        sampleLeaveRequest(id: 'w-$i', employeeName: 'Person $i'),
    ];

    setUp(() {
      repository.myApprovalsPage = (status, cursor) async => Result.success(
        status != LeaveStatus.pending
            ? const CursorPage(items: [])
            : cursor == null
            ? CursorPage(items: rows(0, 20), nextCursor: 'c-2', hasMore: true)
            : CursorPage(items: rows(20, 5)),
      );
    });

    testWidgets('with more than 20 waiting the header says 20+', (
      tester,
    ) async {
      await pumpTab(tester, height: 700);

      expect(find.text(en.leaveApprovalsPendingHeader('20+')), findsOneWidget);
      // Nothing more is asked for until the end of the list comes near.
      expect(
        repository.myApprovalsCalls.where((s) => s == LeaveStatus.pending),
        hasLength(1),
      );
    });

    testWidgets('scrolling to the end of the waiting list loads the rest, '
        'and no card shows twice', (tester) async {
      await pumpTab(tester, height: 700);

      await tester.scrollUntilVisible(
        find.text('Person 19'),
        600,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(repository.myApprovalsCursors, contains('c-2'));
      expect(find.text(en.leaveApprovalsPendingHeader('25')), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Person 24'),
        600,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Person 24'), findsOneWidget);
      // Asked for once only.
      expect(
        repository.myApprovalsCursors.where((c) => c == 'c-2'),
        hasLength(1),
      );
    });
  });

  group('what I decided', () {
    // Lee approved step 1 of each; this is what became of them.
    final waitsForHr = sampleLeaveRequest(
      id: 'req-hr',
      employeeName: 'Bee Keo',
      currentStepNo: 2,
      steps: const [
        LeaveApprovalStep(
          stepNo: 1,
          role: LeaveStepRole.deptHead,
          status: LeaveStepStatus.approved,
        ),
        LeaveApprovalStep(
          stepNo: 2,
          role: LeaveStepRole.hr,
          status: LeaveStepStatus.pending,
        ),
      ],
    );
    final cancelledSince = sampleLeaveRequest(
      id: 'req-c',
      employeeName: 'Somchai P',
      status: LeaveStatus.cancelled,
    );

    setUp(() {
      repository
        ..pendingApprovalsResult = const Result.success([])
        ..approvedByMeResult = Result.success([waitsForHr, cancelledSince])
        ..rejectedByMeResult = Result.success([
          sampleLeaveRequest(
            id: 'req-r',
            employeeName: 'Vanh S',
            status: LeaveStatus.rejected,
          ),
        ]);
    });

    testWidgets('opens on "I approved": a request still waiting shows its '
        'own status and the step it waits for', (tester) async {
      await pumpTab(tester);

      expect(find.text(en.leaveDecidedByMeApproved), findsOneWidget);
      expect(find.text(en.leaveDecidedByMeRejected), findsOneWidget);
      expect(find.textContaining('Bee Keo'), findsOneWidget);
      expect(find.text(en.leaveStatusPending), findsOneWidget);
      expect(find.text('Waiting for HR'), findsOneWidget);
    });

    testWidgets('one the employee cancelled since still shows, as '
        'cancelled, with no waiting line', (tester) async {
      await pumpTab(tester);

      expect(find.textContaining('Somchai P'), findsOneWidget);
      expect(find.text(en.leaveStatusCancelled), findsOneWidget);
      expect(find.textContaining('Waiting for'), findsOneWidget);
    });

    testWidgets('in Lao the waiting line names the step in Lao', (
      tester,
    ) async {
      await pumpTab(tester, locale: 'lo');

      expect(find.text('ລໍຖ້າຝ່າຍບຸກຄະລາກອນ'), findsOneWidget);
    });

    testWidgets('"I rejected" shows the other list', (tester) async {
      await pumpTab(tester);

      await tester.tap(find.text(en.leaveDecidedByMeRejected));
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(repository.myApprovalsCalls.last, LeaveStatus.rejected);
      expect(find.textContaining('Vanh S'), findsOneWidget);
      expect(find.textContaining('Bee Keo'), findsNothing);
      // The row's icon follows the chip: what I did.
      expect(find.byIcon(Icons.close), findsWidgets);
    });
  });
}

/// Answers the approvals lists after [delay], as a real network does, so a
/// frame is drawn while the lists are loading.
class _SlowApprovals extends FakeLeaveRepository {
  Duration delay = Duration.zero;

  @override
  FutureResult<CursorPage<LeaveRequest>> myApprovals({
    LeaveStatus? status,
    String? cursor,
  }) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    return super.myApprovals(status: status, cursor: cursor);
  }
}

extension<T> on T {
  R let<R>(R Function(T it) f) => f(this);
}
