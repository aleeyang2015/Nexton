import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/time_off/domain/entities/leave_status.dart';
import 'package:next_on/core/network/paged_list.dart';
import 'package:next_on/features/time_off/domain/entities/leave_request.dart';
import 'package:next_on/features/time_off/presentation/widgets/leave_approvals_badge_icon.dart';
import 'package:next_on/features/time_off/time_off_providers.dart';

import '../../support/leave_test_doubles.dart';

void main() {
  /// Mounts the icon on its own with [pending] queued behind the use case.
  /// The notifier loads on a microtask, so the badge is only settled after
  /// the extra pump — pass `settle: false` to look at the in-flight frame.
  Future<void> pumpBadge(
    WidgetTester tester,
    Result<List<LeaveRequest>> pending, {
    bool settle = true,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // The cards look the leave type's Lao name up in the type list.
          leaveRepositoryProvider.overrideWithValue(FakeLeaveRepository()),
          getLeaveApprovalsUseCaseProvider.overrideWithValue(
            FakeGetLeaveApprovals(pending: pending),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: LeaveApprovalsBadgeIcon()),
        ),
      ),
    );
    if (settle) await tester.pump();
  }

  testWidgets('counts the requests waiting on this approver', (tester) async {
    await pumpBadge(
      tester,
      Result.success([pendingApproval(id: 'r-1'), pendingApproval(id: 'r-2'), pendingApproval(id: 'r-3')]),
    );

    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('draws no badge when nothing is waiting', (tester) async {
    await pumpBadge(tester, const Result.success([]));

    expect(find.byType(Badge), findsNothing);
    expect(find.byIcon(Icons.approval), findsOneWidget);
  });

  testWidgets('20 loaded with more to load shows 20+, as the header does', (
    tester,
  ) async {
    final repository = FakeLeaveRepository()
      ..myApprovalsPage = (status, cursor) async => Result.success(
        status == LeaveStatus.pending
            ? CursorPage(
                items: [
                  for (var i = 0; i < 20; i++) pendingApproval(id: 'r-$i'),
                ],
                nextCursor: 'c-2',
                hasMore: true,
              )
            : const CursorPage(items: []),
      );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [leaveRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          home: Scaffold(body: LeaveApprovalsBadgeIcon()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('20+'), findsOneWidget);
    // The badge does not load more by itself: one page was asked for.
    expect(
      repository.myApprovalsCalls.where((s) => s == LeaveStatus.pending),
      hasLength(1),
    );
  });

  testWidgets('the last page in: the plain count', (tester) async {
    await pumpBadge(
      tester,
      Result.success([for (var i = 0; i < 20; i++) pendingApproval(id: 'r-$i')]),
    );

    expect(find.text('20'), findsOneWidget);
  });

  testWidgets('caps a runaway queue at 99+', (tester) async {
    await pumpBadge(
      tester,
      Result.success([for (var i = 0; i < 120; i++) pendingApproval(id: 'r-$i')]),
    );

    expect(find.text('99+'), findsOneWidget);
  });

  testWidgets('reports no count while the fetch is still in flight', (
    tester,
  ) async {
    await pumpBadge(tester, Result.success([pendingApproval(id: 'r-1')]), settle: false);

    expect(find.byType(Badge), findsNothing);

    // …and the count lands once the load resolves.
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('a failed fetch shows no badge rather than a wrong one', (
    tester,
  ) async {
    await pumpBadge(
      tester,
      const Result.failure(Failure.network(message: 'boom')),
    );

    expect(find.byType(Badge), findsNothing);
  });
}
