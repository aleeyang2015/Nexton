import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/approvals/approvals_page.dart';
import 'package:next_on/features/attendance/attendance_providers.dart';
import 'package:next_on/features/attendance/domain/entities/offsite_detail.dart';
import 'package:next_on/features/attendance/domain/entities/offsite_method.dart';
import 'package:next_on/features/attendance/domain/entities/time_correction_detail.dart';
import 'package:next_on/features/attendance/domain/entities/time_correction_status.dart';
import 'package:next_on/features/attendance/presentation/widgets/offsite_approvals_tab.dart';
import 'package:next_on/features/time_off/domain/entities/leave_approval_step.dart';
import 'package:next_on/features/time_off/time_off_providers.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';

import '../../support/attendance_test_doubles.dart';
import '../../support/leave_test_doubles.dart';

void main() {
  OffsiteRequestDetail pendingScan({
    String id = 'o-1',
    String employeeName = 'Noy Phommachanh',
    OffsiteMethod method = OffsiteMethod.checkOut,
    double? latitude = 17.9757,
    double? longitude = 102.6331,
    TimeCorrectionStatus status = TimeCorrectionStatus.pending,
  }) => OffsiteRequestDetail(
    id: id,
    employee: TimeCorrectionEmployee(
      name: employeeName,
      employeeNumber: 'EMP-001',
      departmentName: 'Sales',
    ),
    method: method,
    latitude: latitude,
    longitude: longitude,
    scanTimestamp: DateTime(2026, 10, 2, 8, 15),
    scanDate: DateTime(2026, 10, 2),
    sessionOrder: 1,
    shift: null,
    attachmentUrl: 'https://cdn.nexton.work/uploads/abc.jpg',
    reason: 'With a customer',
    status: status,
    currentStepNo: 1,
    attendanceRecordId: null,
    steps: const [
      TimeCorrectionApprovalStep(
        id: 'step-1',
        stepNo: 1,
        role: LeaveStepRole.hr,
        status: LeaveStepStatus.pending,
      ),
    ],
    submittedAt: DateTime(2026, 10, 2, 8, 15),
  );

  /// Mounts the tab on its own with [requests] queued behind the repository.
  /// English, so the assertions read as the copy they check.
  Future<FakeOffsiteRepository> pumpTab(
    WidgetTester tester,
    List<OffsiteRequestDetail> requests,
  ) async {
    final repository = FakeOffsiteRepository()
      ..approvalsResult = Result.success(requests);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [offsiteRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const Scaffold(body: OffsiteApprovalsTab()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return repository;
  }

  group('OffsiteApprovalsTab', () {
    testWidgets('shows who filed the scan, where and when', (tester) async {
      await pumpTab(tester, [pendingScan()]);

      expect(find.text('Noy Phommachanh'), findsOneWidget);
      expect(find.text('EMP-001'), findsOneWidget);
      // The direction it stands in for, the position and the scan time.
      expect(find.text('Clock out'), findsOneWidget);
      expect(find.text('17.97570, 102.63310'), findsOneWidget);
      expect(find.text('08:15'), findsOneWidget);
      expect(find.textContaining('With a customer'), findsOneWidget);
      expect(find.text('Approve'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);
    });

    testWidgets('fetches one list per status the dropdown offers', (
      tester,
    ) async {
      final repository = await pumpTab(tester, [pendingScan()]);

      expect(repository.approvalsStatuses, [
        TimeCorrectionStatus.pending,
        TimeCorrectionStatus.approved,
        TimeCorrectionStatus.rejected,
      ]);
    });

    testWidgets('a request with no position says so instead of "0, 0"', (
      tester,
    ) async {
      await pumpTab(tester, [pendingScan(latitude: null, longitude: null)]);

      expect(find.text('No position'), findsOneWidget);
    });

    testWidgets('an empty inbox reads as empty, not as a failure', (
      tester,
    ) async {
      await pumpTab(tester, []);

      expect(find.text('No off-site scan requests'), findsOneWidget);
      expect(find.text('Approve'), findsNothing);
    });

    testWidgets('approving names the step the card showed as pending', (
      tester,
    ) async {
      final repository = await pumpTab(tester, [pendingScan()]);

      await tester.tap(find.text('Approve'));
      await tester.pumpAndSettle();

      expect(repository.approved, [(id: 'o-1', stepId: 'step-1')]);
    });

    testWidgets('a decided request carries no decision buttons', (
      tester,
    ) async {
      await pumpTab(tester, [
        pendingScan(status: TimeCorrectionStatus.approved),
      ]);

      expect(find.text('Approve'), findsNothing);
      expect(find.text('Reject'), findsNothing);
    });
  });

  group('ApprovalsPage', () {
    /// The whole page, on a small phone and in Lao — the narrowest the three
    /// tabs ever have to share, and the longest their labels get.
    Future<void> pumpPage(WidgetTester tester, {Locale? locale}) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            offsiteRepositoryProvider.overrideWithValue(
              FakeOffsiteRepository(),
            ),
            attendanceRepositoryProvider.overrideWithValue(
              FakeAttendanceRepository(),
            ),
            getLeaveApprovalsUseCaseProvider.overrideWithValue(
              FakeGetLeaveApprovals(pending: const Result.success([])),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: locale ?? const Locale('en'),
            home: const ApprovalsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('carries an off-site tab beside the other two', (tester) async {
      await pumpPage(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Approve Leave'), findsOneWidget);
      expect(find.text('Approve Corrections'), findsOneWidget);
      expect(find.text('Approve Off-site'), findsOneWidget);
    });

    testWidgets('three Lao labels fit a 360pt phone without overflowing', (
      tester,
    ) async {
      await pumpPage(tester, locale: const Locale('lo'));

      expect(tester.takeException(), isNull);
    });

    testWidgets('its tab opens the off-site list', (tester) async {
      await pumpPage(tester);

      await tester.tap(find.text('Approve Off-site'));
      await tester.pumpAndSettle();

      expect(find.byType(OffsiteApprovalsTab), findsOneWidget);
      expect(find.text('No off-site scan requests'), findsOneWidget);
    });

    testWidgets('can be opened straight on the off-site tab', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            offsiteRepositoryProvider.overrideWithValue(
              FakeOffsiteRepository(),
            ),
            attendanceRepositoryProvider.overrideWithValue(
              FakeAttendanceRepository(),
            ),
            getLeaveApprovalsUseCaseProvider.overrideWithValue(
              FakeGetLeaveApprovals(pending: const Result.success([])),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: const ApprovalsPage(initialTab: ApprovalsTab.offsite),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No off-site scan requests'), findsOneWidget);
    });
  });
}
