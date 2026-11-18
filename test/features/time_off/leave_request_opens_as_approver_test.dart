import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:next_on/app/router/app_router.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/auth/domain/entities/user.dart';
import 'package:next_on/features/auth/presentation/providers/auth_session_notifier.dart';
import 'package:next_on/features/time_off/domain/entities/leave_request.dart';
import 'package:next_on/features/time_off/presentation/pages/leave_request_detail_page.dart';
import 'package:next_on/features/time_off/time_off_providers.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';

import '../../support/approver_access_test_doubles.dart';
import '../../support/leave_test_doubles.dart';

/// A push opens the leave page by id (#53); when the request is someone
/// else's, the page hands over to the approver's (#37), with what it
/// loaded. The owner is read from `employee.id` (`employeeId`).
void main() {
  const me = 'b3f1-employees-uuid';
  late FakeLeaveRepository repository;
  late List<Object?> approverExtras;

  setUp(() {
    repository = FakeLeaveRepository();
    approverExtras = [];
  });

  Future<void> open(WidgetTester tester, {required User user}) async {
    tester.view.physicalSize = const Size(390, 1600);
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
        ...leaveRequestRoutes,
        GoRoute(
          path: AppRoutes.approvalLeaveDetail,
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
          leaveRepositoryProvider.overrideWithValue(repository),
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
    unawaited(router.push(AppRoutes.timeOffRequest('req-7')));
    await tester.pumpAndSettle();
  }

  testWidgets('another employee\'s request: replaced by the approver page, '
      'with the loaded request', (tester) async {
    final theirs = sampleLeaveRequest(id: 'req-7', employeeId: 'someone-else');
    repository.requestDetailResult = Result.success(theirs);

    await open(tester, user: approverTestUser());

    expect(find.text('APPROVER req-7'), findsOneWidget);
    expect(find.byType(LeaveRequestDetailPage), findsNothing);
    expect(approverExtras.last, isA<LeaveRequest>());
    expect((approverExtras.last! as LeaveRequest).id, 'req-7');
  });

  testWidgets('my own request: the page stays', (tester) async {
    repository.requestDetailResult = Result.success(
      sampleLeaveRequest(id: 'req-7', employeeId: me),
    );

    await open(tester, user: approverTestUser());

    expect(find.byType(LeaveRequestDetailPage), findsOneWidget);
    expect(find.textContaining('APPROVER'), findsNothing);
  });

  testWidgets('no owner in the answer: the page stays', (tester) async {
    repository.requestDetailResult = Result.success(
      sampleLeaveRequest(id: 'req-7'),
    );

    await open(tester, user: approverTestUser());

    expect(find.byType(LeaveRequestDetailPage), findsOneWidget);
  });

  testWidgets('someone else\'s, but no Approvals for this login: the page '
      'stays', (tester) async {
    repository.requestDetailResult = Result.success(
      sampleLeaveRequest(id: 'req-7', employeeId: 'someone-else'),
    );

    await open(tester, user: approverTestUser(head: false));

    expect(find.byType(LeaveRequestDetailPage), findsOneWidget);
    expect(find.textContaining('APPROVER'), findsNothing);
  });
}
