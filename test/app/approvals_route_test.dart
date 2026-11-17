import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:next_on/app/router/app_router.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/core/widgets/error_page.dart';
import 'package:next_on/features/approvals/approvals_page.dart';
import 'package:next_on/features/attendance/attendance_providers.dart';
import 'package:next_on/features/auth/domain/entities/user.dart';
import 'package:next_on/features/time_off/time_off_providers.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';

import '../support/approver_access_test_doubles.dart';
import '../support/attendance_test_doubles.dart';
import '../support/leave_test_doubles.dart';

/// `/approvals` is for department heads and HR only (decision 8): opened
/// by hand by anyone else, it finds nothing.
void main() {
  Future<void> open(
    WidgetTester tester,
    User user, {
    String location = AppRoutes.approvals,
  }) async {
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
          offsiteRepositoryProvider.overrideWithValue(FakeOffsiteRepository()),
          attendanceRepositoryProvider.overrideWithValue(
            FakeAttendanceRepository(),
          ),
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
    router.push(location);
    await tester.pumpAndSettle();
  }

  testWidgets('plain staff: the not-found page', (tester) async {
    await open(tester, approverTestUser(head: false));

    expect(find.byType(NotFoundPage), findsOneWidget);
    expect(find.byType(ApprovalsPage), findsNothing);
  });

  testWidgets('a head with no staff record: the not-found page (the web)',
      (tester) async {
    await open(tester, approverTestUser(employeeId: null));

    expect(find.byType(NotFoundPage), findsOneWidget);
  });

  testWidgets('a leave request\'s page, opened by hand by plain staff: the '
      'not-found page', (tester) async {
    await open(
      tester,
      approverTestUser(head: false),
      location: AppRoutes.approvalLeave('req-1'),
    );

    expect(find.byType(NotFoundPage), findsOneWidget);
  });

  testWidgets('a department head: the place', (tester) async {
    await open(tester, approverTestUser());

    expect(find.byType(ApprovalsPage), findsOneWidget);
    expect(find.byType(NotFoundPage), findsNothing);
  });

  testWidgets('the admin role with a staff record: the place', (tester) async {
    await open(tester, approverTestUser(head: false, roles: ['admin']));

    expect(find.byType(ApprovalsPage), findsOneWidget);
  });
}
