import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:next_on/app/router/app_router.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/attendance/attendance_providers.dart';
import 'package:next_on/features/attendance/domain/entities/time_correction_detail.dart';
import 'package:next_on/features/attendance/domain/entities/time_correction_status.dart';
import 'package:next_on/features/attendance/domain/entities/time_correction_type.dart';
import 'package:next_on/features/attendance/presentation/pages/time_correction_history_detail_page.dart';
import 'package:next_on/features/auth/domain/entities/user.dart';
import 'package:next_on/features/auth/presentation/providers/auth_session_notifier.dart';
import 'package:next_on/features/time_off/domain/entities/leave_approval_step.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';

import '../../support/approver_access_test_doubles.dart';
import '../../support/attendance_test_doubles.dart';

/// A push opens the "forgot to scan" page by id (#53); when the request is
/// someone else's, the page hands over to the approver's (#47), with what
/// it loaded.
void main() {
  const me = 'b3f1-employees-uuid';
  late FakeAttendanceRepository repository;
  late List<Object?> approverExtras;

  TimeCorrectionDetail request({String? employeeId}) => TimeCorrectionDetail(
    id: 'tc-1',
    employee: TimeCorrectionEmployee(id: employeeId, name: 'Noy'),
    requestDate: DateTime(2026, 11, 14),
    type: TimeCorrectionType.forgotClockOut,
    clockIn: null,
    clockOut: const Duration(hours: 17, minutes: 5),
    shift: const TimeCorrectionShift(
      nameLo: 'ຊ່ວງເຊົ້າ',
      name: 'Morning',
      start: Duration(hours: 8),
      end: Duration(hours: 12),
    ),
    reason: 'Forgot to clock out',
    attachmentUrl: null,
    status: TimeCorrectionStatus.pending,
    currentStepNo: 1,
    steps: const [
      TimeCorrectionApprovalStep(
        stepNo: 1,
        role: LeaveStepRole.deptHead,
        status: LeaveStepStatus.pending,
      ),
    ],
    submittedAt: DateTime(2026, 11, 15, 9),
  );

  setUp(() {
    repository = FakeAttendanceRepository();
    approverExtras = [];
  });

  Future<void> open(WidgetTester tester, {required User user}) async {
    tester.view.physicalSize = const Size(420, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        // Reads the session, as the App's router does before any page.
        GoRoute(
          path: '/',
          builder: (_, _) => Consumer(
            builder: (_, ref, _) {
              ref.watch(authSessionProvider);
              return const Text('HOME');
            },
          ),
        ),
        GoRoute(
          path: AppRoutes.myCorrectionRequestDetail,
          builder: (_, state) =>
              TimeCorrectionHistoryDetailPage(id: state.pathParameters['id']!),
        ),
        GoRoute(
          path: AppRoutes.approvalCorrectionDetail,
          builder: (_, state) {
            approverExtras.add(state.extra);
            return Text('APPROVER ${state.pathParameters['id']}');
          },
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          attendanceRepositoryProvider.overrideWithValue(repository),
          attendanceOwnEmployeeIdProvider.overrideWithValue(user.employeeId),
          signedInAs(user),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
        ),
      ),
    );
    await tester.pump();
    unawaited(router.push(AppRoutes.myCorrectionRequest('tc-1')));
    await tester.pumpAndSettle();
  }

  testWidgets('another employee\'s request: replaced by the approver page, '
      'with the loaded request', (tester) async {
    repository.timeCorrectionDetailResults = [
      Result.success(request(employeeId: 'someone-else')),
    ];

    await open(tester, user: approverTestUser());

    expect(find.text('APPROVER tc-1'), findsOneWidget);
    expect(find.byType(TimeCorrectionHistoryDetailPage), findsNothing);
    expect(approverExtras.last, isA<TimeCorrectionDetail>());
  });

  testWidgets('my own request: the page stays', (tester) async {
    repository.timeCorrectionDetailResults = [
      Result.success(request(employeeId: me)),
    ];

    await open(tester, user: approverTestUser());

    expect(find.byType(TimeCorrectionHistoryDetailPage), findsOneWidget);
    expect(find.textContaining('APPROVER'), findsNothing);
  });

  testWidgets('someone else\'s, but this login may not approve attendance: '
      'the page stays', (tester) async {
    repository.timeCorrectionDetailResults = [
      Result.success(request(employeeId: 'someone-else')),
    ];

    // HR for leave only: Approvals, but not its attendance pages.
    await open(
      tester,
      user: approverTestUser(
        head: false,
        permissions: const ['corehr:leaveRequest:manage'],
      ),
    );

    expect(find.byType(TimeCorrectionHistoryDetailPage), findsOneWidget);
    expect(find.textContaining('APPROVER'), findsNothing);
  });
}
