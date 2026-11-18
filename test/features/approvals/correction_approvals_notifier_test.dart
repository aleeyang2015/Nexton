import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:next_on/app/router/app_router.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/network/paged_list.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/core/widgets/app_toast.dart';
import 'package:next_on/core/widgets/error_page.dart';
import 'package:next_on/features/approvals/approvals_page.dart';
import 'package:next_on/features/attendance/attendance_providers.dart';
import 'package:next_on/features/attendance/data/datasources/approval_decision_code.dart';
import 'package:next_on/features/attendance/data/datasources/correction_error_code.dart';
import 'package:next_on/features/attendance/domain/entities/time_correction_detail.dart';
import 'package:next_on/features/attendance/domain/entities/time_correction_status.dart';
import 'package:next_on/features/attendance/presentation/pages/time_correction_history_detail_page.dart';
import 'package:next_on/features/attendance/presentation/providers/time_correction_approvals_notifier.dart';
import 'package:next_on/features/attendance/presentation/providers/time_correction_decision_notifier.dart';
import 'package:next_on/features/attendance/presentation/widgets/time_correction_approvals_tab.dart';
import 'package:next_on/features/auth/domain/entities/user.dart';
import 'package:next_on/features/auth/presentation/providers/auth_session_notifier.dart';
import 'package:next_on/features/time_off/data/datasources/leave_error_code.dart';
import 'package:next_on/features/time_off/domain/entities/leave_approval_step.dart';
import 'package:next_on/features/time_off/time_off_providers.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';
import 'package:next_on/l10n/generated/app_localizations_en.dart';

import '../../support/approver_access_test_doubles.dart';
import '../../support/attendance_test_doubles.dart';
import '../../support/correction_approval_test_doubles.dart';
import '../../support/leave_test_doubles.dart';

/// The approvals page's "forgot to scan" lists, the decisions on them, and
/// the request's approver page (#47).
void main() {
  final en = AppLocalizationsEn();
  late FakeAttendanceRepository repository;
  late ProviderContainer container;

  final hr = approverTestUser(
    head: false,
    permissions: const ['corehr:attendanceRecord:manage'],
    employeeId: 'e-hr',
  );

  CursorPage<TimeCorrectionDetail> page(
    List<TimeCorrectionDetail> rows, {
    String? next,
  }) => CursorPage(items: rows, nextCursor: next, hasMore: next != null);

  setUp(() {
    repository = FakeAttendanceRepository()
      ..timeCorrectionApprovalsPages = {
        TimeCorrectionStatus.pending: [
          Result.success(page([correctionForApproval()], next: 'c1')),
          Result.success(page([correctionForApproval(id: 'tc-2')])),
        ],
        TimeCorrectionStatus.approved: [
          Result.success(
            page([
              correctionForApproval(
                id: 'tc-9',
                status: TimeCorrectionStatus.approved,
                stepStatus: LeaveStepStatus.approved,
              ),
            ]),
          ),
        ],
        TimeCorrectionStatus.rejected: [Result.success(page([]))],
      };
  });

  Future<void> start({User? user}) async {
    container = ProviderContainer(
      overrides: [
        attendanceRepositoryProvider.overrideWithValue(repository),
        signedInAs(user ?? hr),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authSessionProvider.future);
    final sub = container.listen(
      timeCorrectionApprovalsNotifierProvider,
      (_, _) {},
    );
    addTearDown(sub.close);
    await pumpEventQueue();
  }

  TimeCorrectionDecisionNotifier decision(String id) {
    final provider = timeCorrectionDecisionNotifierProvider(id);
    final sub = container.listen(provider, (_, _) {});
    addTearDown(sub.close);
    return container.read(provider.notifier);
  }

  int callsFor(TimeCorrectionStatus status) => repository
      .timeCorrectionApprovalsCalls
      .where((c) => c.status == status)
      .length;

  List<String> waitingIds() => container
      .read(timeCorrectionApprovalsNotifierProvider)
      .pending
      .value!
      .items
      .map((r) => r.id)
      .toList();

  group('the lists', () {
    test('waiting (status=pending) and "I approved" load together; "I '
        'rejected" asks for status=rejected', () async {
      await start();

      expect(repository.timeCorrectionApprovalsCalls, unorderedEquals([
        (status: TimeCorrectionStatus.pending, cursor: null),
        (status: TimeCorrectionStatus.approved, cursor: null),
      ]));
      expect(waitingIds(), ['tc-1']);

      container
          .read(timeCorrectionApprovalsNotifierProvider.notifier)
          .selectDecided(TimeCorrectionStatus.rejected);
      await pumpEventQueue();
      expect(repository.timeCorrectionApprovalsCalls.last, (
        status: TimeCorrectionStatus.rejected,
        cursor: null,
      ));
    });

    test('a first-page reload that fails while a next page is on its way: '
        'no spinner left behind, the list can go on', () async {
      repository.timeCorrectionApprovalsPages![TimeCorrectionStatus.pending] = [
        Result.success(page([correctionForApproval()], next: 'c1')),
        Result.success(page([correctionForApproval(id: 'tc-2')])),
        const Result.failure(Failure.network(message: 'offline')),
      ];
      await start();
      final lists = container.read(
        timeCorrectionApprovalsNotifierProvider.notifier,
      );

      unawaited(lists.loadMorePending());
      unawaited(lists.refresh());
      await pumpEventQueue();

      final pending = container
          .read(timeCorrectionApprovalsNotifierProvider)
          .pending;
      expect(pending.hasError, isTrue);
      expect(pending.value!.loadingMore, isFalse);
      expect(pending.value!.canLoadMore, isTrue);
    });

    test('the next waiting page is asked for with the cursor, once', () async {
      await start();
      final lists = container.read(
        timeCorrectionApprovalsNotifierProvider.notifier,
      );

      await Future.wait([lists.loadMorePending(), lists.loadMorePending()]);

      expect(callsFor(TimeCorrectionStatus.pending), 2);
      expect(repository.timeCorrectionApprovalsCalls.last.cursor, 'c1');
      expect(waitingIds(), ['tc-1', 'tc-2']);
    });
  });

  group('decisions', () {
    test('approve sends the waiting step\'s id and the note; the row goes '
        'and the lists are read again', () async {
      await start();
      final before = repository.timeCorrectionApprovalsCalls.length;

      final result = await decision('tc-1').approve(
        correctionForApproval(),
        note: ' ok ',
      );
      await pumpEventQueue();

      expect(result!.isSuccess, isTrue);
      expect(repository.approvedTimeCorrections, [
        (id: 'tc-1', stepId: 'step-1', note: 'ok'),
      ]);
      expect(repository.timeCorrectionApprovalsCalls.length, before + 2);
    });

    test('NOT_PENDING (another phone decided it): the row goes at once, and '
        'the lists are read again', () async {
      repository.timeCorrectionApprovalsPages![TimeCorrectionStatus.pending] = [
        Result.success(page([correctionForApproval()])),
        const Result.failure(Failure.network(message: 'offline')),
      ];
      await start();
      repository.approveTimeCorrectionResult = const Result.failure(
        Failure.validation(
          message: ApprovalDecisionCode.tokenAlreadyDecided,
          code: 'NOT_PENDING',
        ),
      );

      await decision('tc-1').approve(correctionForApproval());
      await pumpEventQueue();

      expect(callsFor(TimeCorrectionStatus.pending), 2);
      expect(waitingIds(), isEmpty);
    });

    test('404 (gone): the row goes and the lists are read again', () async {
      await start();
      repository.approveTimeCorrectionResult = const Result.failure(
        Failure.validation(message: CorrectionErrorCode.tokenRequestGone),
      );

      await decision('tc-1').approve(correctionForApproval());
      await pumpEventQueue();

      expect(callsFor(TimeCorrectionStatus.pending), 2);
      expect(waitingIds(), isNot(contains('tc-1')));
    });

    test('STEP_CHANGED reads the lists again too', () async {
      await start();
      repository.approveTimeCorrectionResult = const Result.failure(
        Failure.validation(message: LeaveErrorCode.tokenStepChanged),
      );

      await decision('tc-1').approve(correctionForApproval());
      await pumpEventQueue();

      expect(callsFor(TimeCorrectionStatus.pending), 2);
    });

    test('TOO_EARLY_CHECKIN: the request stays waiting, so the row stays',
        () async {
      await start();
      repository.approveTimeCorrectionResult = const Result.failure(
        Failure.validation(
          message: ApprovalDecisionCode.tokenTooEarlyCheckin,
          code: 'TOO_EARLY_CHECKIN',
        ),
      );
      final before = repository.timeCorrectionApprovalsCalls.length;

      final result = await decision('tc-1').approve(correctionForApproval());
      await pumpEventQueue();

      expect(result!.failureOrNull, isNotNull);
      expect(repository.timeCorrectionApprovalsCalls.length, before);
      expect(waitingIds(), ['tc-1']);
    });

    test('NOT_APPROVER: "your own" on the approver\'s own; buttons go', () async {
      await start();
      repository.approveTimeCorrectionResult = const Result.failure(
        Failure.validation(
          message: ApprovalDecisionCode.tokenAnotherApprover,
          code: 'NOT_APPROVER',
        ),
      );

      final own = await decision('tc-own').approve(
        correctionForApproval(id: 'tc-own', employeeId: 'e-hr'),
      );
      await decision('tc-1').approve(correctionForApproval());

      expect(
        (own!.failureOrNull! as ValidationFailure).message,
        ApprovalDecisionCode.tokenCannotDecideOwn,
      );
      expect(
        container.read(timeCorrectionApprovalsNotifierProvider).notMineIds,
        containsAll(['tc-1']),
      );
    });

    test('a double tap sends once', () async {
      await start();
      final hold = Completer<void>();
      repository.holdTimeCorrectionDecision = hold;
      final notifier = decision('tc-1');

      final first = notifier.approve(correctionForApproval());
      final second = await notifier.approve(correctionForApproval());
      hold.complete();
      await first;

      expect(second, isNull);
      expect(repository.approvedTimeCorrections, hasLength(1));
    });
  });

  group('the tab', () {
    Future<void> pumpTab(WidgetTester tester, {User? user}) async {
      tester.view.physicalSize = const Size(420, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            attendanceRepositoryProvider.overrideWithValue(repository),
            signedInAs(user ?? hr),
          ],
          child: MaterialApp(
            scaffoldMessengerKey: rootScaffoldMessengerKey,
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const Scaffold(body: TimeCorrectionApprovalsTab()),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a waiting row: the asked time beside the part\'s, Approve and '
        'Reject; Approve asks for a note and sends it', (tester) async {
      await pumpTab(tester);

      expect(find.text('Noy Phommachanh'), findsWidgets);
      expect(find.textContaining('17:05'), findsWidgets);
      expect(find.textContaining('08:00'), findsWidgets);
      expect(find.text(en.timeCorrectionApprovalApprove), findsOneWidget);

      await tester.tap(find.text(en.timeCorrectionApprovalApprove));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Seen at 17:05');
      await tester.tap(find.text(en.timeCorrectionApprovalApprove).last);
      await tester.pumpAndSettle();

      expect(repository.approvedTimeCorrections.single.note, 'Seen at 17:05');
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text(en.apprApprovedToast),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the approver\'s own request: a line, no buttons', (
      tester,
    ) async {
      repository.timeCorrectionApprovalsPages![TimeCorrectionStatus.pending] = [
        Result.success(page([correctionForApproval(employeeId: 'e-hr')])),
      ];
      await pumpTab(tester);

      expect(find.text(en.leaveOwnRequestNoActions), findsOneWidget);
      expect(find.text(en.timeCorrectionApprovalApprove), findsNothing);
    });

    testWidgets('a step that is not the approver\'s: no buttons', (
      tester,
    ) async {
      // A plain head on an HR step.
      await pumpTab(tester, user: approverTestUser());

      expect(find.text(en.timeCorrectionApprovalApprove), findsNothing);
    });

    testWidgets('the list could not load: the approver\'s words, not the '
        'employee\'s', (tester) async {
      repository.timeCorrectionApprovalsPages![TimeCorrectionStatus.pending] = [
        const Result.failure(Failure.network(message: 'offline')),
      ];
      await pumpTab(tester);

      expect(find.text(en.timeCorrectionApprovalsLoadFailed), findsOneWidget);
      expect(find.text(en.timeCorrectionHistoryLoadFailed), findsNothing);
    });
  });

  group('the request\'s approver page', () {
    Future<void> open(WidgetTester tester, {User? user}) async {
      tester.view.physicalSize = const Size(420, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('LIST')),
          ),
          GoRoute(
            path: AppRoutes.approvalCorrectionDetail,
            builder: (_, state) => TimeCorrectionHistoryDetailPage(
              id: state.pathParameters['id']!,
              approver: true,
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            attendanceRepositoryProvider.overrideWithValue(repository),
            attendanceOwnEmployeeIdProvider.overrideWithValue(
              (user ?? hr).employeeId,
            ),
            signedInAs(user ?? hr),
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
      unawaited(router.push(AppRoutes.approvalCorrection('tc-1')));
      await tester.pumpAndSettle();
    }

    testWidgets('Approve and Reject when the step is mine, never Cancel nor '
        'the employee\'s contact note', (tester) async {
      repository.timeCorrectionDetailResults = [
        Result.success(correctionForApproval()),
      ];
      await open(tester);

      expect(find.text(en.timeCorrectionApprovalApprove), findsOneWidget);
      expect(find.text(en.timeCorrectionApprovalReject), findsOneWidget);
      expect(find.text(en.leaveCancelAction), findsNothing);
      expect(find.text(en.timeCorrectionContactNote), findsNothing);
    });

    testWidgets('approved, but the page could not be read again (no signal): '
        'the buttons go anyway, so no second approve', (tester) async {
      repository.timeCorrectionDetailResults = [
        Result.success(correctionForApproval()),
        const Result.failure(Failure.network(message: 'offline')),
      ];
      await open(tester);

      await tester.tap(find.text(en.timeCorrectionApprovalApprove));
      await tester.pumpAndSettle();
      await tester.tap(find.text(en.timeCorrectionApprovalApprove).last);
      await tester.pumpAndSettle();

      expect(repository.approvedTimeCorrections, hasLength(1));
      expect(find.text(en.timeCorrectionApprovalApprove), findsNothing);
    });

    testWidgets('approved: the page stays, read again, and shows the '
        'corrected day', (tester) async {
      repository.timeCorrectionDetailResults = [
        Result.success(correctionForApproval()),
        Result.success(
          correctionForApproval(
            status: TimeCorrectionStatus.approved,
            stepStatus: LeaveStepStatus.approved,
            result: TimeCorrectionResult(
              date: DateTime(2026, 11, 14),
              clockIn: DateTime(2026, 11, 14, 8),
              clockOut: DateTime(2026, 11, 14, 17, 5),
              status: 'present',
            ),
          ),
        ),
      ];
      await open(tester);

      await tester.tap(find.text(en.timeCorrectionApprovalApprove));
      await tester.pumpAndSettle();
      await tester.tap(find.text(en.timeCorrectionApprovalApprove).last);
      await tester.pumpAndSettle();

      expect(find.text('LIST'), findsNothing);
      expect(repository.timeCorrectionDetailCalls, hasLength(2));
      expect(find.text(en.attCorrectionResult), findsOneWidget);
      expect(find.text(en.timeCorrectionApprovalApprove), findsNothing);
    });

    testWidgets('the approver\'s own request: a line, no buttons', (
      tester,
    ) async {
      repository.timeCorrectionDetailResults = [
        Result.success(correctionForApproval(employeeId: 'e-hr')),
      ];
      await open(tester);

      expect(find.text(en.leaveOwnRequestNoActions), findsOneWidget);
      expect(find.text(en.timeCorrectionApprovalApprove), findsNothing);
      expect(find.text(en.leaveCancelAction), findsNothing);
    });
  });

  group('routes', () {
    Future<void> openRoute(WidgetTester tester, User user, String at) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const SizedBox.shrink()),
          ...approvalsRoutes,
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            approverAccessOf(user),
            signedInAs(user),
            offsiteRepositoryProvider.overrideWithValue(FakeOffsiteRepository()),
            attendanceRepositoryProvider.overrideWithValue(repository),
            leaveRepositoryProvider.overrideWithValue(FakeLeaveRepository()),
            getLeaveApprovalsUseCaseProvider.overrideWithValue(
              FakeGetLeaveApprovals(pending: const Result.success([])),
            ),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
          ),
        ),
      );
      router.push(at);
      await tester.pumpAndSettle();
    }

    testWidgets('the old approvals address opens Approvals on this tab', (
      tester,
    ) async {
      await openRoute(tester, hr, AppRoutes.timeCorrectionApprovals);

      expect(find.byType(ApprovalsPage), findsOneWidget);
      expect(find.byType(TimeCorrectionApprovalsTab), findsOneWidget);
    });

    testWidgets('neither address is for a leave-only approver', (
      tester,
    ) async {
      final leaveHr = approverTestUser(
        head: false,
        permissions: const ['corehr:leaveRequest:manage'],
      );
      await openRoute(tester, leaveHr, AppRoutes.timeCorrectionApprovals);
      expect(find.byType(NotFoundPage), findsOneWidget);
    });

    testWidgets('a request\'s approver page, by hand, for a leave-only '
        'approver: not found', (tester) async {
      final leaveHr = approverTestUser(
        head: false,
        permissions: const ['corehr:leaveRequest:manage'],
      );
      await openRoute(tester, leaveHr, AppRoutes.approvalCorrection('tc-1'));
      expect(find.byType(NotFoundPage), findsOneWidget);
    });
  });
}
