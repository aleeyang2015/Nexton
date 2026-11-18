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
import 'package:next_on/l10n/generated/app_localizations_en.dart';
import 'package:next_on/features/time_off/presentation/providers/leave_request_detail_notifier.dart';

import '../../support/approver_access_test_doubles.dart';
import '../../support/leave_test_doubles.dart';

/// A push opens the leave page by id (#53); when the request is someone
/// else's, the page hands over to the approver's (#37), with what it
/// loaded. The owner is read from `employee.id` (`employeeId`).
void main() {
  const me = 'b3f1-employees-uuid';
  late _HeldDetail repository;
  late List<Object?> approverExtras;
  late GoRouter router;

  setUp(() {
    repository = _HeldDetail();
    approverExtras = [];
  });

  Future<void> open(
    WidgetTester tester, {
    required User user,
    bool settle = true,
  }) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    router = GoRouter(
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
        GoRoute(path: '/other', builder: (_, _) => const Text('OTHER')),
        GoRoute(
          path: AppRoutes.approvalLeaveDetail,
          builder: (_, state) {
            approverExtras.add(state.extra);
            final id = state.pathParameters['id']!;
            // Shares the request's provider, as #37's page does.
            return Consumer(
              builder: (_, ref, _) {
                ref.watch(leaveRequestDetailNotifierProvider(id));
                return Text('APPROVER $id');
              },
            );
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
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump(const Duration(milliseconds: 300));
    }
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

  testWidgets('the request already loaded (the approver page open beneath): '
      'still handed over, at once', (tester) async {
    repository.requestDetailResult = Result.success(
      sampleLeaveRequest(id: 'req-7', employeeId: 'someone-else'),
    );
    await open(tester, user: approverTestUser());
    expect(find.text('APPROVER req-7'), findsOneWidget);

    // A second push for the same request.
    unawaited(router.push(AppRoutes.timeOffRequest('req-7')));
    await tester.pumpAndSettle();

    expect(find.byType(LeaveRequestDetailPage), findsNothing);
    expect(find.text('APPROVER req-7'), findsOneWidget);
  });

  testWidgets('loaded while another page is on top: waits, then hands over '
      'when on top again; the page above is untouched', (tester) async {
    repository.requestDetailResult = Result.success(
      sampleLeaveRequest(id: 'req-7', employeeId: 'someone-else'),
    );
    repository.hold = Completer<void>();
    await open(tester, user: approverTestUser(), settle: false);
    unawaited(router.push('/other'));
    await tester.pump(const Duration(milliseconds: 500));

    repository.hold!.complete();
    await tester.pumpAndSettle();
    expect(find.text('OTHER'), findsOneWidget);
    expect(approverExtras, isEmpty);

    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('APPROVER req-7'), findsOneWidget);
    expect(find.byType(LeaveRequestDetailPage), findsNothing);
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('someone else\'s pending request on this page (HR with no '
      'staff record): no Edit, no Cancel', (tester) async {
    repository.requestDetailResult = Result.success(
      sampleLeaveRequest(id: 'req-7', employeeId: 'someone-else'),
    );

    await open(
      tester,
      user: approverTestUser(
        head: false,
        employeeId: null,
        permissions: const ['corehr:leaveRequest:manage'],
      ),
    );

    expect(find.byType(LeaveRequestDetailPage), findsOneWidget);
    expect(find.text(AppLocalizationsEn().leaveEditAction), findsNothing);
    expect(find.text(AppLocalizationsEn().leaveCancelAction), findsNothing);
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

/// Answers the by-id load once [hold] completes, when set.
class _HeldDetail extends FakeLeaveRepository {
  Completer<void>? hold;

  @override
  FutureResult<LeaveRequest> requestDetail(String id) async {
    await hold?.future;
    return super.requestDetail(id);
  }
}
