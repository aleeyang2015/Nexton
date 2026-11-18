import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:next_on/app/router/app_router.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/core/widgets/app_toast.dart';
import 'package:next_on/features/attendance/attendance_providers.dart';
import 'package:next_on/features/attendance/data/datasources/offsite_error_code.dart';
import 'package:next_on/features/attendance/domain/entities/offsite_detail.dart';
import 'package:next_on/features/attendance/domain/entities/time_correction_status.dart';
import 'package:next_on/features/attendance/presentation/pages/offsite_request_detail_page.dart';
import 'package:next_on/features/auth/domain/entities/user.dart';
import 'package:next_on/features/time_off/domain/entities/leave_approval_step.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';
import 'package:next_on/l10n/generated/app_localizations_en.dart';

import '../../support/approver_access_test_doubles.dart';
import '../../support/attendance_test_doubles.dart';
import '../../support/offsite_approval_test_doubles.dart';

/// The approver's page of one off-site scan (#46): `/approvals/offsite/:id`.
void main() {
  final en = AppLocalizationsEn();
  late FakeOffsiteRepository repository;

  final hr = approverTestUser(
    head: false,
    permissions: const ['corehr:attendanceRecord:manage'],
    employeeId: 'e-hr',
  );

  setUp(() => repository = FakeOffsiteRepository());

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
          path: AppRoutes.approvalOffsiteDetail,
          builder: (_, state) => OffsiteRequestDetailPage(
            requestId: state.pathParameters['id']!,
            initial: state.extra as OffsiteRequestDetail?,
            approver: true,
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          offsiteRepositoryProvider.overrideWithValue(repository),
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
    unawaited(router.push(AppRoutes.approvalOffsite('o-1')));
    await tester.pumpAndSettle();
  }

  Finder approve() => find.text(en.timeCorrectionApprovalApprove);
  Finder reject() => find.text(en.timeCorrectionApprovalReject);

  testWidgets('the waiting step is the approver\'s: Approve and Reject, never '
      'Cancel', (tester) async {
    repository.detailResults = [Result.success(offsiteForApproval())];
    await open(tester);

    expect(repository.detailCalls, ['o-1']);
    expect(find.text('Noy Phommachanh'), findsOneWidget);
    expect(approve(), findsOneWidget);
    expect(reject(), findsOneWidget);
    expect(find.text(en.offsiteCancelAction), findsNothing);
  });

  testWidgets('approved: says so, and back to the list', (tester) async {
    repository.detailResults = [Result.success(offsiteForApproval())];
    await open(tester);

    await tester.tap(approve());
    await tester.pumpAndSettle();
    await tester.tap(approve().last);
    await tester.pumpAndSettle();

    expect(repository.approved.single.stepId, 'step-1');
    expect(find.text(en.apprApprovedToast), findsOneWidget);
    expect(find.text('LIST'), findsOneWidget);
  });

  testWidgets('decided meanwhile (NOT_PENDING): says so, and shows the '
      'request as it now is, without buttons', (tester) async {
    repository
      ..detailResults = [
        Result.success(offsiteForApproval()),
        Result.success(
          offsiteForApproval(
            status: TimeCorrectionStatus.approved,
            stepStatus: LeaveStepStatus.approved,
          ),
        ),
      ]
      ..decisionResult = const Result.failure(
        Failure.validation(
          message: OffsiteErrorCode.tokenAlreadyDecided,
          code: 'NOT_PENDING',
        ),
      );
    await open(tester);

    await tester.tap(approve());
    await tester.pumpAndSettle();
    await tester.tap(approve().last);
    await tester.pumpAndSettle();

    expect(find.text(en.apprAlreadyDecided), findsOneWidget);
    expect(repository.detailCalls, hasLength(2));
    expect(approve(), findsNothing);
    expect(find.text('LIST'), findsNothing);
  });

  testWidgets('the approver\'s own request: a line, no buttons', (
    tester,
  ) async {
    repository.detailResults = [
      Result.success(offsiteForApproval(employeeId: 'e-hr')),
    ];
    await open(tester);

    expect(find.text(en.leaveOwnRequestNoActions), findsOneWidget);
    expect(approve(), findsNothing);
    expect(find.text(en.offsiteCancelAction), findsNothing);
  });

  testWidgets('a step that is someone else\'s: no buttons', (tester) async {
    repository.detailResults = [
      Result.success(
        offsiteForApproval(role: LeaveStepRole.deptHead, approverId: 'e-other'),
      ),
    ];
    await open(tester, user: approverTestUser(employeeId: 'e-head'));

    expect(approve(), findsNothing);
    expect(reject(), findsNothing);
  });
}
