import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:next_on/app/router/app_router.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/network/paged_list.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/core/widgets/app_toast.dart';
import 'package:next_on/features/attendance/attendance_providers.dart';
import 'package:next_on/features/attendance/data/datasources/correction_error_code.dart';
import 'package:next_on/features/attendance/domain/entities/time_correction_detail.dart';
import 'package:next_on/features/attendance/domain/entities/time_correction_record.dart';
import 'package:next_on/features/attendance/domain/entities/time_correction_status.dart';
import 'package:next_on/features/attendance/domain/entities/time_correction_type.dart';
import 'package:next_on/features/attendance/presentation/pages/my_requests_page.dart';
import 'package:next_on/features/attendance/presentation/pages/time_correction_history_detail_page.dart';
import 'package:next_on/features/attendance/presentation/providers/time_correction_detail_notifier.dart';
import 'package:next_on/features/attendance/presentation/providers/time_correction_history_notifier.dart';
import 'package:next_on/features/attendance/presentation/widgets/time_correction_record_card.dart';
import 'package:next_on/features/attendance/presentation/widgets/time_correction_requests_tab.dart';
import 'package:next_on/features/time_off/domain/entities/leave_approval_step.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';
import 'package:next_on/l10n/generated/app_localizations_en.dart';

import '../../support/attendance_test_doubles.dart';

/// One of the employee's "forgot to scan" requests (#45): its page by id,
/// Cancel, the corrected day, and the paging of "My requests"' tab.
void main() {
  final en = AppLocalizationsEn();
  late FakeAttendanceRepository repository;

  TimeCorrectionDetail request({
    TimeCorrectionStatus status = TimeCorrectionStatus.pending,
    String? employeeId = 'e-1',
    TimeCorrectionResult? result,
  }) => TimeCorrectionDetail(
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
    status: status,
    currentStepNo: status == TimeCorrectionStatus.pending ? 1 : 0,
    steps: [
      TimeCorrectionApprovalStep(
        stepNo: 1,
        role: LeaveStepRole.deptHead,
        status: switch (status) {
          TimeCorrectionStatus.pending => LeaveStepStatus.pending,
          TimeCorrectionStatus.approved => LeaveStepStatus.approved,
          TimeCorrectionStatus.rejected => LeaveStepStatus.rejected,
          TimeCorrectionStatus.cancelled => LeaveStepStatus.pending,
        },
      ),
    ],
    submittedAt: DateTime(2026, 11, 15, 9),
    result: result,
  );

  TimeCorrectionRecord row(String id) => TimeCorrectionRecord(
    id: id,
    submittedAt: DateTime(2026, 11, 15, 9),
    workDate: DateTime(2026, 11, 14),
    type: TimeCorrectionType.forgotClockOut,
    clockIn: null,
    clockOut: const Duration(hours: 17, minutes: 5),
    status: TimeCorrectionStatus.pending,
  );

  setUp(() => repository = FakeAttendanceRepository());

  List<Override> overrides({String? ownEmployeeId = 'e-1'}) => [
    attendanceRepositoryProvider.overrideWithValue(repository),
    attendanceOwnEmployeeIdProvider.overrideWithValue(ownEmployeeId),
  ];

  Future<void> open(
    WidgetTester tester, {
    String? ownEmployeeId = 'e-1',
    TimeCorrectionRecord? initial,
  }) async {
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
          path: AppRoutes.myCorrectionRequestDetail,
          builder: (_, state) => TimeCorrectionHistoryDetailPage(
            id: state.pathParameters['id']!,
            initial: state.extra as TimeCorrectionRecord?,
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(ownEmployeeId: ownEmployeeId),
        child: MaterialApp.router(
          routerConfig: router,
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
        ),
      ),
    );
    unawaited(router.push(AppRoutes.myCorrectionRequest('tc-1'), extra: initial));
    await tester.pumpAndSettle();
  }

  Finder cancelButton() => find.text(en.leaveCancelAction);

  testWidgets('loads the request by its id: part, type, time, reason, steps', (
    tester,
  ) async {
    repository.timeCorrectionDetailResults = [Result.success(request())];
    await open(tester);

    expect(repository.timeCorrectionDetailCalls, ['tc-1']);
    expect(find.text(en.timeCorrectionStatusPending), findsWidgets);
    expect(find.text(en.attCorrectionRequested), findsOneWidget);
    expect(find.text('17:05'), findsOneWidget);
    expect(find.text('"Forgot to clock out"'), findsOneWidget);
    expect(find.text(en.timeCorrectionTypeForgotOut), findsOneWidget);
  });

  group('Cancel', () {
    testWidgets('only on the own employee\'s pending request', (tester) async {
      repository.timeCorrectionDetailResults = [Result.success(request())];
      await open(tester);
      expect(cancelButton(), findsOneWidget);
    });

    testWidgets('not once decided', (tester) async {
      repository.timeCorrectionDetailResults = [
        Result.success(request(status: TimeCorrectionStatus.approved)),
      ];
      await open(tester);
      expect(cancelButton(), findsNothing);
    });

    testWidgets('not on someone else\'s (an approver opening it)', (
      tester,
    ) async {
      repository.timeCorrectionDetailResults = [Result.success(request())];
      await open(tester, ownEmployeeId: 'e-head');
      expect(cancelButton(), findsNothing);
    });

    testWidgets('asks first; withdrawn → says so, and shows it cancelled', (
      tester,
    ) async {
      repository.timeCorrectionDetailResults = [
        Result.success(request()),
        Result.success(request(status: TimeCorrectionStatus.cancelled)),
      ];
      await open(tester);

      await tester.tap(cancelButton());
      await tester.pumpAndSettle();
      expect(repository.cancelledTimeCorrectionIds, isEmpty);
      await tester.tap(cancelButton().last);
      await tester.pumpAndSettle();

      expect(repository.cancelledTimeCorrectionIds, ['tc-1']);
      expect(find.text(en.timeCorrectionCancelled), findsOneWidget);
      // The page stays, read again: the cancelled pill and the steps'
      // cancelled end; no Cancel any more.
      expect(repository.timeCorrectionDetailCalls, hasLength(2));
      expect(find.text(en.timeCorrectionStatusCancelled), findsWidgets);
      expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
      expect(cancelButton(), findsNothing);
      expect(find.text('LIST'), findsNothing);
    });

    testWidgets('decided meanwhile (CANNOT_CANCEL): says so, and shows the '
        'request as it now is', (tester) async {
      repository
        ..timeCorrectionDetailResults = [
          Result.success(request()),
          Result.success(request(status: TimeCorrectionStatus.approved)),
        ]
        ..cancelTimeCorrectionResult = const Result.failure(
          Failure.validation(
            message: CorrectionErrorCode.tokenCannotCancel,
            code: 'CANNOT_CANCEL',
          ),
        );
      await open(tester);

      await tester.tap(cancelButton());
      await tester.pumpAndSettle();
      await tester.tap(cancelButton().last);
      await tester.pumpAndSettle();

      expect(find.text(en.offsiteCannotCancel), findsOneWidget);
      expect(repository.timeCorrectionDetailCalls, hasLength(2));
      expect(find.text(en.timeCorrectionStatusApproved), findsWidgets);
      expect(cancelButton(), findsNothing);
    });

    testWidgets('withdrawn, but the reload failed (no signal): shown '
        'cancelled anyway, no Cancel to tap again', (tester) async {
      repository.timeCorrectionDetailResults = [
        Result.success(request()),
        const Result.failure(Failure.network(message: 'offline')),
      ];
      await open(tester);

      await tester.tap(cancelButton());
      await tester.pumpAndSettle();
      await tester.tap(cancelButton().last);
      await tester.pumpAndSettle();

      expect(repository.cancelledTimeCorrectionIds, ['tc-1']);
      expect(find.text(en.timeCorrectionCancelled), findsOneWidget);
      expect(find.text(en.timeCorrectionStatusCancelled), findsWidgets);
      expect(cancelButton(), findsNothing);
    });

    test('a second cancel while one is on its way tells nothing', () async {
      final container = ProviderContainer(overrides: overrides());
      addTearDown(container.dispose);
      repository.timeCorrectionDetailResults = [Result.success(request())];
      final provider = timeCorrectionDetailNotifierProvider('tc-1');
      final keepAlive = container.listen(provider, (_, _) {});
      addTearDown(keepAlive.close);
      await container.read(provider.notifier).refresh();

      final notifier = container.read(provider.notifier);
      final first = notifier.cancel();
      final second = await notifier.cancel();
      await first;

      expect(second, isNull);
      expect(repository.cancelledTimeCorrectionIds, ['tc-1']);
    });

    test('a withdrawal reads the list behind it again', () async {
      final container = ProviderContainer(overrides: overrides());
      addTearDown(container.dispose);
      repository.timeCorrectionDetailResults = [Result.success(request())];
      final list = container.listen(
        timeCorrectionHistoryNotifierProvider,
        (_, _) {},
      );
      addTearDown(list.close);
      final provider = timeCorrectionDetailNotifierProvider('tc-1');
      final keepAlive = container.listen(provider, (_, _) {});
      addTearDown(keepAlive.close);
      await pumpEventQueue();
      final before = repository.timeCorrectionHistoryCalls.length;

      await container.read(provider.notifier).cancel();
      await pumpEventQueue();

      expect(repository.timeCorrectionHistoryCalls.length, before + 1);
    });
  });

  group('the corrected day ("After the correction")', () {
    testWidgets('only when the answer carries it: clock-in, clock-out and '
        'the day\'s status', (tester) async {
      repository.timeCorrectionDetailResults = [
        Result.success(
          request(
            status: TimeCorrectionStatus.approved,
            result: TimeCorrectionResult(
              date: DateTime(2026, 11, 14),
              clockIn: DateTime(2026, 11, 14, 8, 2),
              clockOut: DateTime(2026, 11, 14, 17, 5),
              status: 'late',
              isLate: true,
              lateMinutes: 2,
            ),
          ),
        ),
      ];
      await open(tester);

      expect(find.text(en.attCorrectionResult), findsOneWidget);
      expect(find.text('08:02'), findsOneWidget);
      // The requested time, and the corrected one.
      expect(find.text('17:05'), findsNWidgets(2));
      expect(find.text(en.attendanceLateByMinutes(2)), findsOneWidget);
    });

    testWidgets('not while it waits', (tester) async {
      repository.timeCorrectionDetailResults = [Result.success(request())];
      await open(tester);

      expect(find.text(en.attCorrectionResult), findsNothing);
    });
  });

  group('when there is no request to show', () {
    testWidgets('gone, or not the user\'s (404): "not available", no Retry', (
      tester,
    ) async {
      repository.timeCorrectionDetailResults = [
        const Result.failure(
          Failure.validation(message: CorrectionErrorCode.tokenRequestGone),
        ),
      ];
      await open(tester, initial: row('tc-1'));

      expect(find.text(en.apprRequestNotFound), findsOneWidget);
      expect(find.text(en.retry), findsNothing);
    });

    testWidgets('no staff record: "not linked", no Retry', (tester) async {
      repository.timeCorrectionDetailResults = [
        const Result.failure(
          Failure.validation(
            message: 'no employee',
            code: 'EMPLOYEE_NOT_FOUND',
          ),
        ),
      ];
      await open(tester);

      expect(find.text(en.timeCorrectionDetailLoadFailed), findsNothing);
      expect(find.text(en.retry), findsNothing);
    });

    testWidgets('another failure: says so with Retry, and Retry loads', (
      tester,
    ) async {
      repository.timeCorrectionDetailResults = [
        const Result.failure(Failure.network(message: 'offline')),
        Result.success(request()),
      ];
      await open(tester, initial: row('tc-1'));

      expect(find.text(en.timeCorrectionDetailLoadFailed), findsOneWidget);
      await tester.tap(find.text(en.retry));
      await tester.pumpAndSettle();

      expect(find.text('"Forgot to clock out"'), findsOneWidget);
    });

    testWidgets('opened with nothing under it: back goes to "My requests" '
        'on its "forgot to scan" tab', (tester) async {
      repository.timeCorrectionDetailResults = [Result.success(request())];
      final router = GoRouter(
        initialLocation: AppRoutes.myCorrectionRequest('tc-1'),
        routes: [
          GoRoute(
            path: AppRoutes.timeCorrectionHistory,
            builder: (_, _) => const Scaffold(body: Text('MY REQUESTS')),
          ),
          GoRoute(
            path: AppRoutes.myCorrectionRequestDetail,
            builder: (_, state) => TimeCorrectionHistoryDetailPage(
              id: state.pathParameters['id']!,
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides(),
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('MY REQUESTS'), findsOneWidget);
    });
  });

  group('the list, a page at a time', () {
    CursorPage<TimeCorrectionRecord> page(int n, {String? next}) => CursorPage(
      items: [for (var i = 0; i < 20; i++) row('p$n-$i')],
      nextCursor: next,
      hasMore: next != null,
    );

    test('the next page is asked for with the cursor, once', () async {
      final container = ProviderContainer(overrides: overrides());
      addTearDown(container.dispose);
      repository.timeCorrectionHistoryResults = [
        Result.success(page(0, next: 'c1')),
        Result.success(page(1)),
      ];
      final sub = container.listen(
        timeCorrectionHistoryNotifierProvider,
        (_, _) {},
      );
      addTearDown(sub.close);
      await pumpEventQueue();

      final notifier = container.read(
        timeCorrectionHistoryNotifierProvider.notifier,
      );
      await Future.wait([notifier.loadMore(), notifier.loadMore()]);
      await notifier.loadMore();

      expect(repository.timeCorrectionHistoryCalls, [
        (status: null, cursor: null),
        (status: null, cursor: 'c1'),
      ]);
      expect(
        container.read(timeCorrectionHistoryNotifierProvider).visible,
        hasLength(40),
      );
    });

    test('a status is a server filter: its own list from its first page', () async {
      final container = ProviderContainer(overrides: overrides());
      addTearDown(container.dispose);
      repository.timeCorrectionHistoryResults = [
        Result.success(page(0, next: 'c1')),
      ];
      final sub = container.listen(
        timeCorrectionHistoryNotifierProvider,
        (_, _) {},
      );
      addTearDown(sub.close);
      await pumpEventQueue();

      container
          .read(timeCorrectionHistoryNotifierProvider.notifier)
          .selectFilter(TimeCorrectionStatus.approved);
      await pumpEventQueue();

      expect(repository.timeCorrectionHistoryCalls.last, (
        status: TimeCorrectionStatus.approved,
        cursor: null,
      ));
    });

    test('a failed refresh keeps the rows already shown', () async {
      final container = ProviderContainer(overrides: overrides());
      addTearDown(container.dispose);
      repository.timeCorrectionHistoryResults = [
        Result.success(page(0)),
        const Result.failure(Failure.network(message: 'offline')),
      ];
      final sub = container.listen(
        timeCorrectionHistoryNotifierProvider,
        (_, _) {},
      );
      addTearDown(sub.close);
      await pumpEventQueue();

      final failure = await container
          .read(timeCorrectionHistoryNotifierProvider.notifier)
          .refresh();

      expect(failure, isNotNull);
      expect(
        container.read(timeCorrectionHistoryNotifierProvider).visible,
        hasLength(20),
      );
    });

    testWidgets('the tab asks for the next page on scroll, not as soon as a '
        'page lands', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      repository.timeCorrectionHistoryResults = [
        for (var p = 0; p < 5; p++) Result.success(page(p, next: 'c$p')),
      ];
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides(),
          child: const MaterialApp(
            locale: Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(body: TimeCorrectionRequestsTab()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(repository.timeCorrectionHistoryCalls, hasLength(1));

      await tester.drag(find.byType(ListView), const Offset(0, -20000));
      await tester.pumpAndSettle();
      expect(repository.timeCorrectionHistoryCalls, hasLength(2));
    });

    testWidgets('switching tabs and back keeps the picked status and the '
        'rows, with no new request', (tester) async {
      tester.view.physicalSize = const Size(420, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      repository.timeCorrectionHistoryResults = [
        Result.success(CursorPage.single([row('tc-1')])),
      ];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...overrides(),
            offsiteRepositoryProvider.overrideWithValue(FakeOffsiteRepository()),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: MyRequestsPage(initialTab: MyRequestsTab.correction),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(repository.timeCorrectionHistoryCalls, hasLength(1));

      await tester.tap(find.text(en.attOffsiteTab));
      await tester.pumpAndSettle();
      await tester.tap(find.text(en.attCorrectionTab));
      await tester.pumpAndSettle();

      expect(repository.timeCorrectionHistoryCalls, hasLength(1));
      expect(find.byType(TimeCorrectionRecordCard), findsOneWidget);
    });

    testWidgets('a row opens its request\'s own page, with the row', (
      tester,
    ) async {
      repository
        ..timeCorrectionHistoryResults = [
          Result.success(CursorPage.single([row('tc-1')])),
        ]
        ..timeCorrectionDetailResults = [Result.success(request())];
      final router = GoRouter(
        initialLocation: AppRoutes.timeCorrectionHistory,
        routes: [
          GoRoute(
            path: AppRoutes.timeCorrectionHistory,
            builder: (_, _) =>
                const MyRequestsPage(initialTab: MyRequestsTab.correction),
          ),
          GoRoute(
            path: AppRoutes.myCorrectionRequestDetail,
            builder: (_, state) => TimeCorrectionHistoryDetailPage(
              id: state.pathParameters['id']!,
              initial: state.extra as TimeCorrectionRecord?,
            ),
          ),
        ],
      );
      tester.view.physicalSize = const Size(420, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...overrides(),
            // The off-site tab beside it loads too.
            offsiteRepositoryProvider.overrideWithValue(FakeOffsiteRepository()),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The old history address opens "My requests" on this tab.
      expect(find.text(en.attCorrectionTab), findsOneWidget);
      await tester.tap(find.byType(TimeCorrectionRecordCard));
      await tester.pumpAndSettle();

      expect(repository.timeCorrectionDetailCalls, ['tc-1']);
      expect(find.text('"Forgot to clock out"'), findsOneWidget);
    });
  });
}
