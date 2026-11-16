import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/time_off/domain/entities/leave_request.dart';
import 'package:next_on/features/time_off/presentation/widgets/leave_approvals_tab.dart';
import 'package:next_on/features/time_off/time_off_providers.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';

import '../../support/leave_test_doubles.dart';

void main() {
  /// Mounts the approvals tab with [pending] queued behind the use case.
  /// English so the assertions read as the copy they check.
  Future<void> pumpTab(
    WidgetTester tester,
    List<LeaveRequest> pending,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          getLeaveApprovalsUseCaseProvider.overrideWithValue(
            FakeGetLeaveApprovals(pending: Result.success(pending)),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const Scaffold(body: LeaveApprovalsTab()),
        ),
      ),
    );
    await tester.pump();
  }

  group('still with its first approver', () {
    testWidgets('flags the request as new and offers a plain approve', (
      tester,
    ) async {
      await pumpTab(tester, [pendingApproval(reason: 'Family matter')]);

      expect(find.text('New'), findsOneWidget);
      expect(find.text('Approve'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);
    });

    testWidgets('claims no earlier approval it has not had', (tester) async {
      await pumpTab(tester, [pendingApproval()]);

      expect(find.textContaining('Approved by'), findsNothing);
      expect(find.text('Final approval'), findsNothing);
    });

    testWidgets('shows the reason the employee gave', (tester) async {
      await pumpTab(tester, [pendingApproval(reason: 'Family matter')]);

      expect(find.text('"Family matter"'), findsOneWidget);
    });
  });

  group('already cleared by the dept head', () {
    testWidgets('names who approved it and calls the decision final', (
      tester,
    ) async {
      await pumpTab(tester, [pendingApproval(clearedByDeptHead: true)]);

      expect(find.text('Approved by the department head'), findsOneWidget);
      expect(find.text('Final approval'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);
    });

    testWidgets('drops the new badge — it is no longer untouched', (
      tester,
    ) async {
      await pumpTab(tester, [pendingApproval(clearedByDeptHead: true)]);

      expect(find.text('New'), findsNothing);
      expect(find.text('Approve'), findsNothing);
    });
  });

  testWidgets('each card is staged on its own', (tester) async {
    await pumpTab(tester, [
      pendingApproval(id: 'r-1', employeeName: 'Kham Souvanna'),
      pendingApproval(
        id: 'r-2',
        employeeName: 'Noy Phommachanh',
        clearedByDeptHead: true,
      ),
    ]);

    expect(find.text('Needs your approval (2)'), findsOneWidget);
    expect(find.text('New'), findsOneWidget);
    expect(find.text('Approve'), findsOneWidget);
    expect(find.text('Final approval'), findsOneWidget);
    expect(find.text('Approved by the department head'), findsOneWidget);
  });
}
