import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/network/paged_list.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/core/widgets/app_toast.dart';
import 'package:next_on/features/attendance/data/datasources/offsite_error_code.dart';
import 'package:next_on/features/auth/domain/entities/user.dart';
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

import '../../support/approver_access_test_doubles.dart';
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
    String employeeId = 'e-noy',
  }) => OffsiteRequestDetail(
    id: id,
    employee: TimeCorrectionEmployee(
      id: employeeId,
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

  /// HR, by the attendance permission: the HR steps of [pendingScan] are
  /// theirs to decide.
  final hr = approverTestUser(
    head: false,
    permissions: const ['corehr:attendanceRecord:manage'],
    employeeId: 'e-hr',
  );

  /// Mounts the tab on its own with [requests] waiting and nothing decided,
  /// signed in as [user] (HR by default). English, so the assertions read as
  /// the copy they check.
  Future<FakeOffsiteRepository> pumpTab(
    WidgetTester tester,
    List<OffsiteRequestDetail> requests, {
    List<OffsiteRequestDetail> decided = const [],
    User? user,
  }) async {
    tester.view.physicalSize = const Size(420, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repository = FakeOffsiteRepository()
      ..approvalsPages = {
        TimeCorrectionStatus.pending: [
          Result.success(CursorPage.single(requests)),
        ],
        TimeCorrectionStatus.approved: [
          Result.success(CursorPage.single(decided)),
        ],
        TimeCorrectionStatus.rejected: [
          const Result.success(CursorPage.single([])),
        ],
      };

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          offsiteRepositoryProvider.overrideWithValue(repository),
          signedInAs(user ?? hr),
        ],
        child: MaterialApp(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
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

    testWidgets('waiting and "I approved" load together; the other chip '
        'asks for its own list', (tester) async {
      final repository = await pumpTab(tester, [pendingScan()]);

      // The exact calls are the notifier test's; here, which lists.
      expect(repository.approvalsCalls.toSet(), {
        (status: TimeCorrectionStatus.pending, cursor: null),
        (status: TimeCorrectionStatus.approved, cursor: null),
      });

      await tester.tap(find.text('I rejected'));
      await tester.pumpAndSettle();
      expect(repository.approvalsCalls.last, (
        status: TimeCorrectionStatus.rejected,
        cursor: null,
      ));
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

      expect(find.text('Nothing needs your approval'), findsOneWidget);
      expect(find.text('Approve'), findsNothing);
    });

    testWidgets('Approve asks first, with an optional note; it sends the '
        'waiting step and the note', (tester) async {
      final repository = await pumpTab(tester, [pendingScan()]);

      await tester.tap(find.text('Approve'));
      await tester.pumpAndSettle();
      expect(repository.approved, isEmpty);
      await tester.enterText(find.byType(TextField).last, 'OK, client visit');
      await tester.tap(find.text('Approve').last);
      await tester.pumpAndSettle();

      expect(repository.approved, [
        (id: 'o-1', stepId: 'step-1', note: 'OK, client visit'),
      ]);
      expect(find.text('Approved'), findsOneWidget);
    });

    testWidgets('the approver\'s own request: a line, no buttons', (
      tester,
    ) async {
      await pumpTab(tester, [pendingScan(employeeId: 'e-hr')]);

      expect(
        find.text('This is your own request. Someone else must decide it.'),
        findsOneWidget,
      );
      expect(find.text('Approve'), findsNothing);
    });

    testWidgets('a step that is not the approver\'s: no buttons', (
      tester,
    ) async {
      // A plain head on an HR step.
      await pumpTab(tester, [pendingScan()], user: approverTestUser());

      expect(find.text('Approve'), findsNothing);
      expect(find.text('Reject'), findsNothing);
    });

    testWidgets('a decided request carries no decision buttons', (
      tester,
    ) async {
      await pumpTab(tester, [], decided: [
        pendingScan(status: TimeCorrectionStatus.approved),
      ]);

      expect(find.text('Noy Phommachanh'), findsOneWidget);
      expect(find.text('Approve'), findsNothing);
      expect(find.text('Reject'), findsNothing);
    });

    testWidgets('the check-in was turned down (CHECKIN_NOT_APPROVED): says '
        'so, and only Reject is left', (tester) async {
      final repository = await pumpTab(tester, [pendingScan()]);
      repository.decisionResult = const Result.failure(
        Failure.validation(
          message: OffsiteErrorCode.tokenCheckinNotApproved,
          code: 'CHECKIN_NOT_APPROVED',
        ),
      );

      await tester.tap(find.text('Approve'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Approve').last);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'The check-in was rejected or cancelled; this can only be rejected',
        ),
        findsOneWidget,
      );
      expect(find.text('Approve'), findsNothing);
      expect(find.text('Reject'), findsOneWidget);
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
            // The cards look the leave type's Lao name up in the type list.
            leaveRepositoryProvider.overrideWithValue(FakeLeaveRepository()),
            getLeaveApprovalsUseCaseProvider.overrideWithValue(
              FakeGetLeaveApprovals(pending: const Result.success([])),
            ),
            approverAccessOf(),
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
      expect(
        find.descendant(
          of: find.byType(OffsiteApprovalsTab),
          matching: find.text('Nothing needs your approval'),
        ),
        findsOneWidget,
      );
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
            // The cards look the leave type's Lao name up in the type list.
            leaveRepositoryProvider.overrideWithValue(FakeLeaveRepository()),
            getLeaveApprovalsUseCaseProvider.overrideWithValue(
              FakeGetLeaveApprovals(pending: const Result.success([])),
            ),
            approverAccessOf(),
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

      expect(
        find.descendant(
          of: find.byType(OffsiteApprovalsTab),
          matching: find.text('Nothing needs your approval'),
        ),
        findsOneWidget,
      );
    });
  });
}
