import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:next_on/app/router/app_router.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/network/paged_list.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/core/widgets/error_page.dart';
import 'package:next_on/features/approvals/approvals_page.dart';
import 'package:next_on/features/approvals/domain/approver_access.dart';
import 'package:next_on/features/approvals/presentation/widgets/team_tab.dart';
import 'package:next_on/features/attendance/attendance_providers.dart';
import 'package:next_on/features/attendance/data/datasources/correction_error_code.dart';
import 'package:next_on/features/attendance/domain/entities/time_correction_status.dart';
import 'package:next_on/features/auth/domain/entities/user.dart';
import 'package:next_on/features/time_off/data/datasources/leave_error_code.dart';
import 'package:next_on/features/time_off/domain/entities/leave_approval_step.dart';
import 'package:next_on/features/time_off/presentation/widgets/leave_copy.dart';
import 'package:next_on/features/time_off/presentation/widgets/leave_filter_chip.dart';
import 'package:next_on/features/time_off/time_off_providers.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';
import 'package:next_on/l10n/generated/app_localizations_en.dart';

import '../../support/approver_access_test_doubles.dart';
import '../../support/attendance_test_doubles.dart';
import '../../support/correction_approval_test_doubles.dart';
import '../../support/leave_test_doubles.dart';

/// "ທີມຂອງຂ້ອຍ" (#50): who sees it, the read-only pages, a 404 that keeps
/// the row.
void main() {
  final en = AppLocalizationsEn();
  late FakeLeaveRepository leave;
  late FakeAttendanceRepository attendance;

  const me = 'e-head';
  final head = approverTestUser(employeeId: me);

  setUp(() {
    leave = FakeLeaveRepository();
    attendance = FakeAttendanceRepository();
  });

  group('who sees the tab', () {
    test('heads only: not plain staff, not HR who heads nothing', () {
      expect(
        ApprovalsTab.visibleFor(ApproverAccess.of(head)),
        contains(ApprovalsTab.team),
      );
      expect(
        ApprovalsTab.visibleFor(
          ApproverAccess.of(approverTestUser(head: false)),
        ),
        isNot(contains(ApprovalsTab.team)),
      );
      expect(
        ApprovalsTab.visibleFor(
          ApproverAccess.of(
            approverTestUser(
              head: false,
              permissions: const ['corehr:leaveRequest:manage'],
            ),
          ),
        ),
        isNot(contains(ApprovalsTab.team)),
      );
    });
  });

  Future<GoRouter> open(
    WidgetTester tester,
    String location, {
    Object? extra,
    User? user,
  }) async {
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
        ...approvalsRoutes,
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          approverAccessOf(user ?? head),
          signedInAs(user ?? head),
          leaveRepositoryProvider.overrideWithValue(leave),
          attendanceRepositoryProvider.overrideWithValue(attendance),
          attendanceOwnEmployeeIdProvider.overrideWithValue(
            (user ?? head).employeeId,
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
    unawaited(router.push(location, extra: extra));
    await tester.pumpAndSettle();
    return router;
  }

  group('a team member\'s leave, read-only', () {
    testWidgets('no buttons, even on a request waiting at my step', (
      tester,
    ) async {
      // Waiting at a head step naming me: an approver would get buttons.
      final request = sampleLeaveRequest(
        id: 'lr-1',
        employeeId: 'e-noy',
        reason: 'Family visit',
        steps: const [
          LeaveApprovalStep(
            id: 's-1',
            stepNo: 1,
            role: LeaveStepRole.deptHead,
            approverId: me,
            status: LeaveStepStatus.pending,
          ),
        ],
      );
      leave.requestDetailResult = Result.success(request);
      await open(tester, AppRoutes.teamLeave('lr-1'), extra: request);

      expect(find.text('Noy Phommachanh'), findsWidgets);
      expect(find.text(en.leaveApprovalApproveAction), findsNothing);
      expect(find.text(en.leaveApprovalRejectAction), findsNothing);
    });

    testWidgets('the page\'s own read answers 404 (moved department): the '
        'row\'s copy stays, no error', (tester) async {
      final request = sampleLeaveRequest(id: 'lr-1', reason: 'Family visit');
      leave.requestDetailResult = const Result.failure(
        Failure.validation(message: LeaveErrorCode.tokenRequestGone),
      );
      await open(tester, AppRoutes.teamLeave('lr-1'), extra: request);

      expect(find.text('Noy Phommachanh'), findsWidgets);
      expect(find.text(en.leaveRequestGone), findsNothing);
      expect(find.text(en.pushItemUnavailable), findsNothing);
    });
  });

  group('a team member\'s "forgot to scan", read-only', () {
    testWidgets('no Approve / Reject, no Cancel', (tester) async {
      // Waiting at a head step naming me: an approver would get buttons.
      final request = correctionForApproval(
        id: 'tc-1',
        role: LeaveStepRole.deptHead,
        approverId: me,
      );
      attendance.timeCorrectionDetailResults = [Result.success(request)];
      await open(tester, AppRoutes.teamCorrection('tc-1'), extra: request);

      expect(find.text(en.timeCorrectionApprovalApprove), findsNothing);
      expect(find.text(en.leaveCancelAction), findsNothing);
      expect(find.text(en.timeCorrectionContactNote), findsNothing);
    });

    testWidgets('404 on the page\'s own read: the row\'s copy stays', (
      tester,
    ) async {
      final request = correctionForApproval(id: 'tc-1');
      attendance.timeCorrectionDetailResults = [
        const Result.failure(
          Failure.validation(message: CorrectionErrorCode.tokenRequestGone),
        ),
      ];
      await open(tester, AppRoutes.teamCorrection('tc-1'), extra: request);

      expect(find.text('"Forgot to clock out"'), findsOneWidget);
      expect(find.text(en.apprRequestNotFound), findsNothing);
    });
  });

  testWidgets('a team page opened by HR who heads nothing (Approvals yes, '
      'My team no): not found', (tester) async {
    await open(
      tester,
      AppRoutes.teamLeave('lr-1'),
      user: approverTestUser(
        head: false,
        permissions: const ['corehr:leaveRequest:manage'],
      ),
    );
    expect(find.byType(NotFoundPage), findsOneWidget);
  });

  testWidgets('the tab: leave first; "forgot to scan" loads only when shown', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    leave.teamPage = (status, cursor) async => Result.success(
      CursorPage.single([sampleLeaveRequest(id: 'lr-1', employeeId: 'e-noy')]),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          signedInAs(head),
          leaveRepositoryProvider.overrideWithValue(leave),
          attendanceRepositoryProvider.overrideWithValue(attendance),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(body: TeamTab()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Noy Phommachanh'), findsOneWidget);
    expect(attendance.teamCorrectionCalls, isEmpty);

    await tester.tap(find.text(en.apprTeamCorrections));
    await tester.pumpAndSettle();
    expect(attendance.teamCorrectionCalls, hasLength(1));
    expect(find.text(en.apprTeamEmpty), findsOneWidget);

    // A chip narrows by status, on the server.
    await tester.tap(find.text(en.timeCorrectionStatusPending));
    await tester.pumpAndSettle();
    expect(
      attendance.teamCorrectionCalls.last.status,
      TimeCorrectionStatus.pending,
    );
    expect(leave.teamCalls.first.status, isNull);

    // Back to leave and again: each list keeps its chip and its pages.
    await tester.tap(find.text(en.apprTeamLeave));
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.apprTeamCorrections));
    await tester.pumpAndSettle();
    expect(leave.teamCalls, hasLength(1));
    expect(attendance.teamCorrectionCalls, hasLength(2));
    expect(
      tester
          .widget<LeaveFilterChip>(
            find.widgetWithText(LeaveFilterChip, en.timeCorrectionStatusPending),
          )
          .selected,
      isTrue,
    );
  });

  test('the days of a team row: not in a row, and a day listed twice', () {
    expect(
      LeaveCopy.teamDays(
        en,
        sampleLeaveRequest(
          requestDays: [DateTime(2026, 9, 15), DateTime(2026, 9, 1)],
        ),
      ),
      startsWith('1, 15 Sep 2026'),
    );
    expect(
      LeaveCopy.teamDays(
        en,
        sampleLeaveRequest(
          requestDays: [
            DateTime(2026, 9, 1),
            DateTime(2026, 9, 1),
            DateTime(2026, 9, 15),
          ],
          totalDays: 2,
        ),
      ),
      startsWith('1, 15 Sep 2026'),
    );
  });
}
