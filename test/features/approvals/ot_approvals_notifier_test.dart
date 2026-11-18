import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:next_on/app/router/app_router.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/utils/clock_provider.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/approvals/approvals_page.dart';
import 'package:next_on/features/approvals/domain/approver_access.dart';
import 'package:next_on/features/auth/domain/entities/user.dart';
import 'package:next_on/features/auth/presentation/providers/auth_session_notifier.dart';
import 'package:next_on/features/overtime/domain/entities/ot_page.dart';
import 'package:next_on/features/overtime/domain/entities/ot_request.dart';
import 'package:next_on/features/overtime/domain/entities/ot_step.dart';
import 'package:next_on/features/overtime/overtime_providers.dart';
import 'package:next_on/features/overtime/presentation/providers/ot_approvals_notifier.dart';
import 'package:next_on/features/overtime/presentation/widgets/ot_approvals_tab.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';
import 'package:next_on/l10n/generated/app_localizations_en.dart';

import '../../support/approver_access_test_doubles.dart';
import '../../support/overtime_test_doubles.dart';

/// The head's OT lists on the approvals page (#48).
void main() {
  final en = AppLocalizationsEn();
  late FakeOtRepository repository;
  late ProviderContainer container;

  const me = 'e-head';
  final head = approverTestUser(employeeId: me);

  OtStep step(
    int no,
    OtStepRole role,
    OtStepStatus status, {
    String? approverId,
  }) => OtStep(
    id: 's-$no',
    stepNo: no,
    role: role,
    status: status,
    approverId: approverId,
  );

  /// Waiting at the head's step (`dept_head`, or `specific` read as unknown).
  OtRequest atHead(String id, {OtStepRole role = OtStepRole.deptHead}) =>
      sampleOt(
        id,
        reason: 'Stocktake',
        steps: [step(1, role, OtStepStatus.pending, approverId: me)],
      );

  /// Waiting at an HR step (an HR login that is also a head sees these).
  OtRequest atHr(String id) => sampleOt(
    id,
    steps: [
      step(1, OtStepRole.deptHead, OtStepStatus.approved, approverId: 'e-x'),
      step(2, OtStepRole.hr, OtStepStatus.pending),
    ],
  );

  OtPage<OtRequest> page(List<OtRequest> rows, int n, int of) =>
      OtPage(items: rows, page: n, totalPages: of);

  setUp(() => repository = FakeOtRepository());

  Future<void> start({User? user}) async {
    container = ProviderContainer(
      overrides: [
        otRepositoryProvider.overrideWithValue(repository),
        signedInAs(user ?? head),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authSessionProvider.future);
    final sub = container.listen(otApprovalsNotifierProvider, (_, _) {});
    addTearDown(sub.close);
    await pumpEventQueue();
  }

  OtApprovalsState read() => container.read(otApprovalsNotifierProvider);

  List<({OtApprovalStatus status, int page})> calls() => [
    for (final c in repository.approvalCalls) (status: c.status, page: c.page),
  ];

  group('the lists and their status', () {
    test('waiting asks status=pending, "I approved" status=approved, '
        'together; "I rejected" asks status=rejected', () async {
      await start();

      expect(
        calls(),
        unorderedEquals([
          (status: OtApprovalStatus.pending, page: 1),
          (status: OtApprovalStatus.approved, page: 1),
        ]),
      );

      container
          .read(otApprovalsNotifierProvider.notifier)
          .selectDecided(OtApprovalStatus.rejected);
      await pumpEventQueue();
      expect(calls().last, (status: OtApprovalStatus.rejected, page: 1));
    });

    test('the next page is asked for by number, once', () async {
      repository.approvalsAnswer = (status, n) => Result.success(
        status == OtApprovalStatus.pending
            ? page([for (var i = 0; i < 20; i++) atHead('p$n-$i')], n, 2)
            : page([], 1, 1),
      );
      await start();
      final lists = container.read(otApprovalsNotifierProvider.notifier);

      await Future.wait([lists.loadMorePending(), lists.loadMorePending()]);
      await lists.loadMorePending();

      expect(calls().where((c) => c.status == OtApprovalStatus.pending), [
        (status: OtApprovalStatus.pending, page: 1),
        (status: OtApprovalStatus.pending, page: 2),
      ]);
      expect(read().pendingRows, hasLength(40));
      expect(repository.approvalCalls.every((c) => c.perPage == 20), isTrue);
    });
  });

  group('HR steps are hidden', () {
    test(
      'waiting: an HR step is dropped; dept_head and specific are kept',
      () async {
        repository.approvalsAnswer = (status, n) => Result.success(
          status == OtApprovalStatus.pending
              ? page(
                  [
                    atHead('head'),
                    atHead('specific', role: OtStepRole.unknown),
                    atHr('hr'),
                  ],
                  1,
                  1,
                )
              : page([], 1, 1),
        );
        await start();

        expect(read().pendingRows.map((r) => r.id), ['head', 'specific']);
      },
    );

    test('decided: a step I decided as HR is dropped; my head step is kept, '
        'and a request I approved that still waits for HR shows', () async {
      final headApprovedWaitingHr = sampleOt(
        'mine-head',
        steps: [
          step(1, OtStepRole.deptHead, OtStepStatus.approved, approverId: me),
          step(2, OtStepRole.hr, OtStepStatus.pending),
        ],
      );
      final iApprovedAsHr = sampleOt(
        'mine-hr',
        status: OtStatus.approved,
        steps: [
          step(
            1,
            OtStepRole.deptHead,
            OtStepStatus.approved,
            approverId: 'e-x',
          ),
          step(2, OtStepRole.hr, OtStepStatus.approved, approverId: me),
        ],
      );
      repository.approvalsAnswer = (status, n) => Result.success(
        status == OtApprovalStatus.approved
            ? page([headApprovedWaitingHr, iApprovedAsHr], 1, 1)
            : page([], 1, 1),
      );
      await start();

      expect(read().decidedRows.map((r) => r.id), ['mine-head']);
      expect(read().decidedRows.single.status, OtStatus.pending);
    });

    test('a page left with no rows (all HR steps) asks for the next page by '
        'itself, so the list is never "none" while more exist', () async {
      repository.approvalsAnswer = (status, n) => Result.success(
        status != OtApprovalStatus.pending
            ? page([], 1, 1)
            : n == 1
            ? page([for (var i = 0; i < 20; i++) atHr('hr-$i')], 1, 3)
            : n == 2
            ? page([for (var i = 0; i < 20; i++) atHr('hr2-$i')], 2, 3)
            : page([atHead('found')], 3, 3),
      );
      await start();

      expect(
        calls()
            .where((c) => c.status == OtApprovalStatus.pending)
            .map((c) => c.page),
        [1, 2, 3],
      );
      expect(read().pendingRows.map((r) => r.id), ['found']);
      expect(read().pending.value!.hasMore, isFalse);
    });

    test(
      'a full page of rows does not ask for the next one by itself',
      () async {
        repository.approvalsAnswer = (status, n) => Result.success(
          status == OtApprovalStatus.pending
              ? page([for (var i = 0; i < 20; i++) atHead('p-$i')], n, 3)
              : page([], 1, 1),
        );
        await start();

        expect(
          calls().where((c) => c.status == OtApprovalStatus.pending),
          hasLength(1),
        );
      },
    );
  });

  test('a failed first page: the shared error, not "none"', () async {
    repository.approvalsAnswer = (status, n) =>
        const Result.failure(Failure.network(message: 'offline'));
    await start();
    expect(read().pending.hasError, isTrue);
  });

  group('review fixes', () {
    test('a decided step that cannot be matched to me: an HR decision never '
        'shows; a head-only decision does', () {
      final hrUnmatched = sampleOt(
        'hr',
        status: OtStatus.approved,
        steps: [
          step(1, OtStepRole.deptHead, OtStepStatus.approved, approverId: 'x'),
          step(2, OtStepRole.hr, OtStepStatus.approved),
        ],
      );
      final headUnmatched = sampleOt(
        'head',
        steps: [
          step(1, OtStepRole.deptHead, OtStepStatus.approved, approverId: 'x'),
          step(2, OtStepRole.hr, OtStepStatus.pending),
        ],
      );
      for (final id in [me, null]) {
        expect(
          OtApprovalsState.keeps(hrUnmatched, OtApprovalStatus.approved, id),
          isFalse,
        );
        expect(
          OtApprovalsState.keeps(headUnmatched, OtApprovalStatus.approved, id),
          isTrue,
        );
      }
    });

    test(
      'nothing is asked for before the session names the employee',
      () async {
        await start(user: approverTestUser(employeeId: null));
        expect(repository.approvalCalls, isEmpty);
      },
    );

    test('a failed pull to refresh is returned, the rows kept', () async {
      var fail = false;
      repository.approvalsAnswer = (status, n) => fail
          ? const Result.failure(Failure.network(message: 'offline'))
          : Result.success(
              status == OtApprovalStatus.pending
                  ? page([atHead('a')], 1, 1)
                  : page([], 1, 1),
            );
      await start();
      fail = true;

      final failure = await container
          .read(otApprovalsNotifierProvider.notifier)
          .refresh();

      expect(failure, isNotNull);
      expect(read().pendingRows.map((r) => r.id), ['a']);
    });
  });

  group('the tab', () {
    Future<void> pumpTab(WidgetTester tester, {bool settle = true}) async {
      tester.view.physicalSize = const Size(420, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: OtApprovalsTab()),
          ),
          GoRoute(
            path: AppRoutes.otRequestDetail,
            builder: (_, state) =>
                Scaffold(body: Text('OT:${state.pathParameters['id']}')),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            otRepositoryProvider.overrideWithValue(repository),
            signedInAs(head),
            clockProvider.overrideWithValue(() => DateTime(2026, 11, 15, 12)),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
          ),
        ),
      );
      if (settle) {
        await tester.pumpAndSettle();
      } else {
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
      }
    }

    testWidgets('a waiting row: name, number and department, the day and '
        'window, the reason, how long it has waited; a tap opens it', (
      tester,
    ) async {
      final request = OtRequest(
        id: 'ot-1',
        employeeId: 'e-noy',
        employeeName: 'Noy',
        employeeNumber: 'EMP-014',
        departmentName: 'Kitchen',
        workDate: DateTime(2026, 11, 14),
        startTime: '22:00',
        endTime: '02:00',
        endsNextDay: true,
        reason: 'Stocktake',
        status: OtStatus.pending,
        createdAt: DateTime(2026, 11, 15, 9),
        steps: [step(1, OtStepRole.deptHead, OtStepStatus.pending)],
      );
      repository.approvalsAnswer = (status, n) => Result.success(
        status == OtApprovalStatus.pending
            ? page([request], 1, 1)
            : page([], 1, 1),
      );
      await pumpTab(tester);

      expect(find.text('Noy'), findsOneWidget);
      expect(find.text('EMP-014 · Kitchen'), findsOneWidget);
      expect(
        find.text('14/11/2026 · 22:00–02:00 ${en.otNextDay}'),
        findsOneWidget,
      );
      expect(find.text('Stocktake'), findsOneWidget);
      expect(find.text(en.apprWaitingHours(3)), findsOneWidget);

      await tester.tap(find.text('Noy'));
      await tester.pumpAndSettle();
      expect(find.text('OT:ot-1'), findsOneWidget);
    });

    testWidgets('a first page of HR steps only, the next on its way: a '
        'spinner, never "none"', (tester) async {
      final page2 = Completer<void>();
      repository
        ..holdApprovalPages[2] = page2
        ..approvalsAnswer = (status, n) => Result.success(
          status != OtApprovalStatus.pending
              ? page([], 1, 1)
              : n == 1
              ? page([for (var i = 0; i < 20; i++) atHr('hr-$i')], 1, 2)
              : page([atHead('found')], 2, 2),
        );
      await pumpTab(tester, settle: false);

      expect(repository.approvalCalls.map((c) => c.page), contains(2));
      expect(find.text(en.apprOtWaitingEmpty), findsNothing);
      page2.complete();
      await tester.pumpAndSettle();
      expect(find.text('Stocktake'), findsOneWidget);
    });

    testWidgets('pages of HR steps, then the next page fails: its Retry, '
        'never "none"', (tester) async {
      repository.approvalsAnswer = (status, n) =>
          status != OtApprovalStatus.pending
          ? Result.success(page([], 1, 1))
          : n == 1
          ? Result.success(page([atHr('hr-1'), atHr('hr-2')], 1, 3))
          : const Result.failure(Failure.network(message: 'offline'));
      await pumpTab(tester);

      expect(find.text(en.apprOtWaitingEmpty), findsNothing);
      expect(find.text(en.retry), findsOneWidget);
    });

    testWidgets('no staff record: #28\'s text, no Retry', (tester) async {
      repository.approvalsAnswer = (status, n) => const Result.failure(
        Failure.validation(
          message: 'otEmployeeNotFound',
          code: 'EMPLOYEE_NOT_FOUND',
        ),
      );
      await pumpTab(tester);

      expect(find.text(en.otListLoadFailed), findsNothing);
      expect(find.text(en.retry), findsNothing);
    });

    testWidgets('nothing waiting: "No OT is waiting for you"', (tester) async {
      await pumpTab(tester);
      expect(find.text(en.apprOtWaitingEmpty), findsOneWidget);
    });

    testWidgets('a decided row that still waits for HR says so', (
      tester,
    ) async {
      repository.approvalsAnswer = (status, n) => Result.success(
        status == OtApprovalStatus.approved
            ? page(
                [
                  sampleOt(
                    'ot-9',
                    steps: [
                      step(
                        1,
                        OtStepRole.deptHead,
                        OtStepStatus.approved,
                        approverId: me,
                      ),
                      step(2, OtStepRole.hr, OtStepStatus.pending),
                    ],
                  ),
                ],
                1,
                1,
              )
            : page([], 1, 1),
      );
      await pumpTab(tester);

      expect(find.text(en.otWaitingFor(en.leaveStepHr)), findsOneWidget);
    });
  });

  group('the Approvals tab', () {
    test('for heads only', () {
      expect(
        ApprovalsTab.visibleFor(ApproverAccess.of(head)),
        contains(ApprovalsTab.ot),
      );
      final attendanceHr = approverTestUser(
        head: false,
        permissions: const ['corehr:attendanceRecord:manage'],
      );
      expect(
        ApprovalsTab.visibleFor(ApproverAccess.of(attendanceHr)),
        isNot(contains(ApprovalsTab.ot)),
      );
    });
  });
}
