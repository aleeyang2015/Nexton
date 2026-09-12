import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/time_off/domain/entities/leave_request.dart';
import 'package:next_on/features/time_off/domain/entities/leave_status.dart';
import 'package:next_on/features/time_off/domain/entities/leave_type.dart';
import 'package:next_on/features/time_off/domain/usecases/get_leave_approvals_usecase.dart';
import 'package:next_on/features/time_off/presentation/widgets/leave_approvals_badge_icon.dart';
import 'package:next_on/features/time_off/time_off_providers.dart';

/// Answers the pending query with [pending] and the unfiltered history query
/// with nothing — the badge only ever counts the former.
class _FakeGetLeaveApprovals implements GetLeaveApprovalsUseCase {
  _FakeGetLeaveApprovals(this.pending);

  final Result<List<LeaveRequest>> pending;

  @override
  FutureResult<List<LeaveRequest>> call(LeaveStatus? status) async =>
      status == LeaveStatus.pending ? pending : const Result.success([]);
}

LeaveRequest _request(String id) => LeaveRequest(
  id: id,
  employeeName: 'Somphone Vilaysone',
  leaveType: const LeaveType(id: 'lt-1', code: 'annual', name: 'Annual'),
  startDate: DateTime(2026, 9, 14),
  endDate: DateTime(2026, 9, 15),
  totalDays: 2,
  status: LeaveStatus.pending,
);

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
          getLeaveApprovalsUseCaseProvider.overrideWithValue(
            _FakeGetLeaveApprovals(pending),
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
      Result.success([_request('r-1'), _request('r-2'), _request('r-3')]),
    );

    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('draws no badge when nothing is waiting', (tester) async {
    await pumpBadge(tester, const Result.success([]));

    expect(find.byType(Badge), findsNothing);
    expect(find.byIcon(Icons.approval), findsOneWidget);
  });

  testWidgets('caps a runaway queue at 99+', (tester) async {
    await pumpBadge(
      tester,
      Result.success([for (var i = 0; i < 120; i++) _request('r-$i')]),
    );

    expect(find.text('99+'), findsOneWidget);
  });

  testWidgets('reports no count while the fetch is still in flight', (
    tester,
  ) async {
    await pumpBadge(tester, Result.success([_request('r-1')]), settle: false);

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
