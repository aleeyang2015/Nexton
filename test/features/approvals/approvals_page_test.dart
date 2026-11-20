import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/approvals/approvals_page.dart';
import 'package:next_on/features/approvals/domain/approver_access.dart';
import 'package:next_on/features/approvals/presentation/providers/approver_access_provider.dart';
import 'package:next_on/features/attendance/attendance_providers.dart';
import 'package:next_on/features/attendance/presentation/widgets/offsite_approvals_tab.dart';
import 'package:next_on/features/auth/domain/entities/user.dart';
import 'package:next_on/features/time_off/presentation/widgets/leave_approvals_tab.dart';
import 'package:next_on/features/time_off/time_off_providers.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';
import 'package:next_on/l10n/generated/app_localizations_en.dart';
import 'package:next_on/l10n/generated/app_localizations_lo.dart';

import '../../support/approver_access_test_doubles.dart';
import '../../support/attendance_test_doubles.dart';
import '../../support/leave_test_doubles.dart';

/// Each section of the Approvals place only for those who may decide it.
void main() {
  final en = AppLocalizationsEn();
  final leave = en.approvalsLeaveTab;
  final corrections = en.approvalsTimeCorrectionTab;
  final offsite = en.approvalsOffsiteTab;

  test('the menu and the tabs say what #36, #46 and #47 ask, in both '
      'languages', () {
    final lo = AppLocalizationsLo();
    expect(lo.approvalsMenu, 'ການອະນຸມັດ');
    expect(en.approvalsMenu, 'Approvals');
    expect(lo.approvalsLeaveTab, 'ລາພັກ');
    expect(en.approvalsLeaveTab, 'Leave');
    expect(lo.approvalsTimeCorrectionTab, 'ລືມລົງເວລາ');
    expect(en.approvalsTimeCorrectionTab, 'Forgot to scan');
    expect(lo.approvalsOffsiteTab, 'ລົງເວລານອກພື້ນທີ່');
    expect(en.approvalsOffsiteTab, 'Off-site scans');
  });

  List<Override> fakes() => [
    offsiteRepositoryProvider.overrideWithValue(FakeOffsiteRepository()),
    attendanceRepositoryProvider.overrideWithValue(FakeAttendanceRepository()),
    leaveRepositoryProvider.overrideWithValue(FakeLeaveRepository()),
    getLeaveApprovalsUseCaseProvider.overrideWithValue(
      FakeGetLeaveApprovals(pending: const Result.success([])),
    ),
  ];

  Future<void> pump(
    WidgetTester tester,
    User user, {
    ApprovalsTab initialTab = ApprovalsTab.leave,
  }) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [approverAccessOf(user), ...fakes()],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: ApprovalsPage(initialTab: initialTab),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a department head: all three sections', (tester) async {
    await pump(tester, approverTestUser());

    expect(find.text(leave), findsOneWidget);
    expect(find.text(corrections), findsOneWidget);
    expect(find.text(offsite), findsOneWidget);
  });

  testWidgets('leave HR only: the leave section alone, its tab bar still shown',
      (tester) async {
    await pump(
      tester,
      approverTestUser(
        head: false,
        permissions: [ApproverAccess.leaveManagePermission],
      ),
    );

    expect(find.byType(TabBar), findsOneWidget);
    expect(find.text(leave), findsOneWidget);
    expect(find.text(corrections), findsNothing);
    expect(find.text(offsite), findsNothing);
    expect(find.byType(LeaveApprovalsTab), findsOneWidget);
  });

  testWidgets('attendance HR only: off-site and "forgot to scan", no leave; '
      'asked to open on leave, it opens on the first it has', (tester) async {
    await pump(
      tester,
      approverTestUser(
        head: false,
        permissions: [ApproverAccess.attendanceManagePermission],
      ),
    );

    expect(find.text(leave), findsNothing);
    expect(find.text(corrections), findsOneWidget);
    expect(find.text(offsite), findsOneWidget);
    expect(find.byType(LeaveApprovalsTab), findsNothing);
  });

  testWidgets('opened on off-site: that tab', (tester) async {
    await pump(tester, approverTestUser(), initialTab: ApprovalsTab.offsite);

    expect(find.byType(OffsiteApprovalsTab), findsOneWidget);
  });

  testWidgets('the sections change while open (resume): the tabs follow, '
      'with no error', (tester) async {
    final access = StateProvider<ApproverAccess>(
      (_) => ApproverAccess.of(approverTestUser()),
    );
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          approverAccessProvider.overrideWith((ref) => ref.watch(access)),
          ...fakes(),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: ApprovalsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(offsite), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(ApprovalsPage)),
    );
    container.read(access.notifier).state = ApproverAccess.of(
      approverTestUser(
        head: false,
        permissions: [ApproverAccess.leaveManagePermission],
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(leave), findsOneWidget);
    expect(find.text(offsite), findsNothing);
  });
}
