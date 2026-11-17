import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:next_on/app/router/app_router.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/core/widgets/app_toast.dart';
import 'package:next_on/features/approvals/presentation/pages/leave_approval_detail_page.dart';
import 'package:next_on/features/approvals/presentation/providers/leave_approval_decision_notifier.dart';
import 'package:next_on/features/auth/domain/entities/user.dart';
import 'package:next_on/features/time_off/domain/entities/leave_approval_step.dart';
import 'package:next_on/features/time_off/domain/entities/leave_request.dart';
import 'package:next_on/features/time_off/domain/entities/leave_status.dart';
import 'package:next_on/features/time_off/presentation/widgets/leave_approvals_tab.dart';
import 'package:next_on/features/time_off/presentation/widgets/leave_copy.dart';
import 'package:next_on/features/time_off/time_off_providers.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';
import 'package:next_on/l10n/generated/app_localizations_en.dart';

import '../../support/approver_access_test_doubles.dart';
import '../../support/leave_test_doubles.dart';

/// Answers approve after [hold] completes, when set.
class _HeldLeave extends FakeLeaveRepository {
  Completer<void>? hold;

  /// When set, the next by-id load waits for it.
  Completer<void>? holdDetail;

  @override
  FutureResult<LeaveRequest> requestDetail(String id) async {
    final answer = requestDetailResult;
    final h = holdDetail;
    holdDetail = null;
    requestDetailCalls.add(id);
    await h?.future;
    return answer;
  }

  @override
  FutureResult<LeaveRequest> approve({
    required String id,
    String? stepId,
    String? note,
  }) async {
    final answer = approveResult;
    final h = hold;
    hold = null;
    final result = super.approve(id: id, stepId: stepId, note: note);
    await h?.future;
    await result;
    return answer;
  }
}

/// Bee's leave, waiting on Lee (her head), and what Lee sees of it.
void main() {
  final en = AppLocalizationsEn();
  late _HeldLeave repository;

  final lee = approverTestUser(employeeId: 'emp-lee');

  LeaveApprovalStep step(
    int no,
    LeaveStepRole role,
    LeaveStepStatus status, {
    String? approverId,
    String? name,
    String? note,
  }) => LeaveApprovalStep(
    id: 'step-$no',
    stepNo: no,
    role: role,
    status: status,
    approverId: approverId,
    approverName: name,
    note: note,
  );

  LeaveRequest bees({
    String reason = 'Medical check-up',
    LeaveStatus status = LeaveStatus.pending,
    List<DateTime>? days,
    String employeeId = 'emp-bee',
    bool atHr = false,
  }) => sampleLeaveRequest(
    id: 'req-bee',
    employeeId: employeeId,
    employeeName: 'Bee Keomany',
    employeeNumber: 'EMP-0042',
    departmentName: 'Kitchen',
    reason: reason,
    status: status,
    requestDays: days ?? [DateTime(2026, 9, 1), DateTime(2026, 9, 15)],
    steps: [
      step(
        1,
        LeaveStepRole.deptHead,
        atHr ? LeaveStepStatus.approved : LeaveStepStatus.pending,
        approverId: 'emp-lee',
        name: 'Lee',
      ),
      step(
        2,
        LeaveStepRole.hr,
        atHr ? LeaveStepStatus.pending : LeaveStepStatus.waiting,
      ),
    ],
  );

  setUp(() {
    repository = _HeldLeave()..requestDetailResult = Result.success(bees());
  });

  /// The page at `/approvals/leave/req-bee`, pushed over a plain page so a
  /// decision can go back.
  Future<GoRouter> open(
    WidgetTester tester, {
    User? user,
    LeaveRequest? initial,
    bool settle = true,
  }) async {
    tester.view.physicalSize = const Size(420, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('LIST')),
        ),
        ...approvalsRoutes,
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          leaveRepositoryProvider.overrideWithValue(repository),
          signedInAs(user ?? lee),
          approverAccessOf(user ?? lee),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
        ),
      ),
    );
    unawaited(router.push(AppRoutes.approvalLeave('req-bee'), extra: initial));
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
    return router;
  }

  Finder inDialog(String text) =>
      find.descendant(of: find.byType(AlertDialog), matching: find.text(text));

  testWidgets('loads the request by its id, showing the list row first',
      (tester) async {
    final slow = Completer<void>();
    repository.holdDetail = slow;
    await open(tester, initial: bees(reason: 'From the list'), settle: false);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('From the list'), findsOneWidget);

    slow.complete();
    await tester.pumpAndSettle();

    expect(repository.requestDetailCalls, ['req-bee']);
    expect(find.text('Medical check-up'), findsOneWidget);
    expect(find.text('From the list'), findsNothing);
  });

  testWidgets('who asked: name, number and department', (tester) async {
    await open(tester);

    expect(find.text(en.apprEmployeeLabel), findsOneWidget);
    expect(find.text('Bee Keomany'), findsOneWidget);
    expect(find.text('EMP-0042'), findsOneWidget);
    expect(find.text('Kitchen'), findsOneWidget);
  });

  testWidgets('every day is listed: 1 and 15 September, not a range alone',
      (tester) async {
    await open(tester);

    expect(find.text(LeaveCopy.shortDate(en, DateTime(2026, 9, 1))),
        findsOneWidget);
    expect(find.text(LeaveCopy.shortDate(en, DateTime(2026, 9, 15))),
        findsOneWidget);
  });

  testWidgets('a single day is listed too', (tester) async {
    repository.requestDetailResult = Result.success(
      bees(days: [DateTime(2026, 9, 1)]),
    );
    await open(tester);

    expect(find.text(en.leaveSelectDatesLabel), findsOneWidget);
    expect(find.text(LeaveCopy.shortDate(en, DateTime(2026, 9, 1))),
        findsOneWidget);
  });

  testWidgets('the named head of the waiting step: Approve and Reject',
      (tester) async {
    await open(tester);

    expect(find.text(en.leaveApprovalApproveAction), findsOneWidget);
    expect(find.text(en.leaveApprovalRejectAction), findsOneWidget);
  });

  testWidgets('no buttons: a decided request, one\'s own, or a step that is '
      'not the user\'s', (tester) async {
    repository.requestDetailResult = Result.success(
      bees(status: LeaveStatus.approved),
    );
    await open(tester);
    expect(find.text(en.leaveApprovalRejectAction), findsNothing);

    repository.requestDetailResult = Result.success(bees(employeeId: 'emp-lee'));
    await open(tester);
    expect(find.text(en.leaveApprovalRejectAction), findsNothing);

    repository.requestDetailResult = Result.success(bees(atHr: true));
    await open(tester);
    expect(find.text(en.leaveApprovalRejectAction), findsNothing);
  });

  testWidgets('Approve asks first; Cancel sends nothing', (tester) async {
    await open(tester);

    await tester.tap(find.text(en.leaveApprovalApproveAction));
    await tester.pumpAndSettle();
    expect(find.text(en.apprApproveConfirmTitle), findsOneWidget);
    expect(find.text(en.apprApproveLastStepHint), findsNothing);

    await tester.tap(find.text(en.cancel));
    await tester.pumpAndSettle();

    expect(repository.approveCalls, isEmpty);
  });

  testWidgets('the last step says the days come off the balance now',
      (tester) async {
    final hr = approverTestUser(
      head: false,
      permissions: ['corehr:leaveRequest:manage'],
      employeeId: 'emp-hr',
    );
    repository.requestDetailResult = Result.success(bees(atHr: true));
    await open(tester, user: hr);

    await tester.tap(find.text(en.leaveApprovalFinalAction));
    await tester.pumpAndSettle();

    expect(find.text(en.apprApproveLastStepHint), findsOneWidget);
  });

  testWidgets('Approve sends the note as approver_note and the step id, says '
      '"Approved" and goes back', (tester) async {
    await open(tester);

    await tester.tap(find.text(en.leaveApprovalApproveAction));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Get well soon');
    await tester.tap(inDialog(en.leaveApprovalApproveAction));
    await tester.pumpAndSettle();

    expect(repository.approveCalls.single, (
      id: 'req-bee',
      stepId: 'step-1',
      note: 'Get well soon',
    ));
    expect(find.text(en.apprApprovedToast), findsOneWidget);
    expect(find.text('LIST'), findsOneWidget);
    expect(find.byType(LeaveApprovalDetailPage), findsNothing);
  });

  testWidgets('decided meanwhile (STEP_CHANGED): says so, stays, reloads with '
      'the new status and no buttons', (tester) async {
    await open(tester);
    repository
      ..approveResult = const Result.failure(
        Failure.validation(message: 'leaveStepChanged'),
      )
      ..requestDetailResult = Result.success(bees(status: LeaveStatus.rejected));

    await tester.tap(find.text(en.leaveApprovalApproveAction));
    await tester.pumpAndSettle();
    await tester.tap(inDialog(en.leaveApprovalApproveAction));
    await tester.pumpAndSettle();

    expect(find.text(en.leaveStepChanged), findsOneWidget);
    expect(find.byType(LeaveApprovalDetailPage), findsOneWidget);
    expect(repository.requestDetailCalls, hasLength(2));
    expect(find.text(en.leaveApprovalRejectAction), findsNothing);
  });

  testWidgets('no signal: says so, the buttons stay for a retry', (tester) async {
    await open(tester);
    repository.approveResult = const Result.failure(
      Failure.network(message: 'offline'),
    );

    await tester.tap(find.text(en.leaveApprovalApproveAction));
    await tester.pumpAndSettle();
    await tester.tap(inDialog(en.leaveApprovalApproveAction));
    await tester.pumpAndSettle();

    expect(find.byType(LeaveApprovalDetailPage), findsOneWidget);
    expect(find.text(en.leaveApprovalRejectAction), findsOneWidget);
    expect(repository.requestDetailCalls, hasLength(1));
  });

  testWidgets('Reject sends the reason typed, says "Rejected" and goes back',
      (tester) async {
    await open(tester);

    await tester.tap(find.text(en.leaveApprovalRejectAction));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Busy week');
    await tester.pump();
    await tester.tap(inDialog(en.leaveRejectReasonSubmit));
    await tester.pumpAndSettle();

    expect(repository.rejectCalls.single.reason, 'Busy week');
    expect(repository.rejectCalls.single.stepId, 'step-1');
    expect(find.text(en.apprRejectedToast), findsOneWidget);
    expect(find.text('LIST'), findsOneWidget);
  });

  test('a second decision while one is on its way sends nothing', () async {
    final container = ProviderContainer(
      overrides: [leaveRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final provider = leaveApprovalDecisionNotifierProvider('req-bee');
    container.listen(provider, (_, _) {});
    final notifier = container.read(provider.notifier);
    final slow = Completer<void>();
    repository.hold = slow;

    final first = notifier.approve(bees());
    expect(container.read(provider), isTrue);
    final second = await notifier.approve(bees());
    slow.complete();
    await first;

    expect(second.abandoned, isTrue);
    expect(repository.approveCalls, hasLength(1));
    expect(container.read(provider), isFalse);
  });

  testWidgets('tapping a card in the list opens the request', (tester) async {
    repository.pendingApprovalsResult = Result.success([bees()]);
    tester.view.physicalSize = const Size(420, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: LeaveApprovalsTab()),
        ),
        ...approvalsRoutes,
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          leaveRepositoryProvider.overrideWithValue(repository),
          leaveOwnEmployeeIdProvider.overrideWithValue('emp-lee'),
          signedInAs(lee),
          approverAccessOf(lee),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bee Keomany'));
    await tester.pumpAndSettle();

    expect(find.byType(LeaveApprovalDetailPage), findsOneWidget);
    expect(find.text('EMP-0042'), findsOneWidget);
  });
}
