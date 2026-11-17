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
import 'package:next_on/features/attendance/data/datasources/offsite_error_code.dart';
import 'package:next_on/features/attendance/domain/entities/offsite_detail.dart';
import 'package:next_on/features/attendance/domain/entities/offsite_method.dart';
import 'package:next_on/features/attendance/domain/entities/time_correction_status.dart';
import 'package:next_on/features/attendance/presentation/pages/offsite_request_detail_page.dart';
import 'package:next_on/features/attendance/presentation/providers/offsite_history_notifier.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';
import 'package:next_on/features/attendance/presentation/widgets/offsite_requests_tab.dart';
import 'package:next_on/features/attendance/presentation/providers/offsite_detail_notifier.dart';
import 'package:next_on/features/attendance/presentation/providers/attendance_notifier.dart';
import 'package:next_on/features/attendance/presentation/pages/my_requests_page.dart';
import 'package:next_on/l10n/generated/app_localizations_en.dart';

import '../../support/attendance_test_doubles.dart';

/// One of the employee's off-site requests (#42), and the paging of the list.
void main() {
  final en = AppLocalizationsEn();
  late FakeOffsiteRepository repository;

  OffsiteRequestDetail scan({
    String id = 'off-1',
    TimeCorrectionStatus status = TimeCorrectionStatus.pending,
  }) => waitingOffsite(
    id: id,
    method: OffsiteMethod.checkIn,
    at: DateTime(2026, 10, 2, 8, 15),
    status: status,
  );

  setUp(() => repository = FakeOffsiteRepository());

  Future<void> open(
    WidgetTester tester, {
    OffsiteRequestDetail? initial,
  }) async {
    tester.view.physicalSize = const Size(420, 2000);
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
          path: AppRoutes.myOffsiteRequestDetail,
          builder: (_, state) => OffsiteRequestDetailPage(
            requestId: state.pathParameters['id']!,
            initial: state.extra as OffsiteRequestDetail?,
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [offsiteRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(
          routerConfig: router,
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
        ),
      ),
    );
    unawaited(router.push(AppRoutes.myOffsiteRequest('off-1'), extra: initial));
    await tester.pumpAndSettle();
  }

  testWidgets('loads the request by its id', (tester) async {
    repository.detailResults = [Result.success(scan())];
    await open(tester);

    expect(repository.detailCalls, ['off-1']);
    expect(find.text('Awaiting approval'), findsWidgets);
  });

  testWidgets('a waiting request offers Cancel; a decided one does not', (
    tester,
  ) async {
    repository.detailResults = [Result.success(scan())];
    await open(tester);
    expect(find.text(en.offsiteCancelAction), findsOneWidget);

    repository.detailResults = [
      Result.success(scan(status: TimeCorrectionStatus.approved)),
    ];
    repository.detailCalls.clear();
    await open(tester);
    expect(find.text(en.offsiteCancelAction), findsNothing);
  });

  testWidgets(
    'Cancel asks first; withdrawn → says so, and shows it cancelled',
    (tester) async {
      repository.detailResults = [
        Result.success(scan()),
        Result.success(scan(status: TimeCorrectionStatus.cancelled)),
      ];
      await open(tester);

      await tester.tap(find.text(en.offsiteCancelAction));
      await tester.pumpAndSettle();
      expect(repository.cancelled, isEmpty);
      await tester.tap(find.text(en.offsiteCancelAction).last);
      await tester.pumpAndSettle();

      expect(repository.cancelled, ['off-1']);
      expect(find.text(en.offsiteCancelled), findsOneWidget);
      expect(repository.detailCalls, hasLength(2));
      expect(find.text(en.offsiteCancelAction), findsNothing);
    },
  );

  testWidgets('decided meanwhile (CANNOT_CANCEL): says so, and shows the real '
      'status', (tester) async {
    repository
      ..detailResults = [
        Result.success(scan()),
        Result.success(scan(status: TimeCorrectionStatus.approved)),
      ]
      ..cancelResult = const Result.failure(
        Failure.validation(message: OffsiteErrorCode.tokenCannotCancel),
      );
    await open(tester);

    await tester.tap(find.text(en.offsiteCancelAction));
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.offsiteCancelAction).last);
    await tester.pumpAndSettle();

    expect(find.text(en.offsiteCannotCancel), findsOneWidget);
    expect(find.text(en.offsiteCancelAction), findsNothing);
  });

  testWidgets('gone, or not the user\'s (404): "this request is not '
      'available", no Retry', (tester) async {
    repository.detailResults = [
      const Result.failure(
        Failure.validation(message: OffsiteErrorCode.tokenRequestGone),
      ),
    ];
    await open(tester, initial: scan());

    expect(find.text(en.apprRequestNotFound), findsOneWidget);
    expect(find.text(en.retry), findsNothing);
  });

  group('the list, a page at a time', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [offsiteRepositoryProvider.overrideWithValue(repository)],
      );
    });

    tearDown(() => container.dispose());

    test('the next page is asked for with the cursor, once', () async {
      repository.myRequestsPages = [
        Result.success(
          CursorPage(
            items: [scan(id: 'a')],
            nextCursor: 'c2',
            hasMore: true,
          ),
        ),
        Result.success(CursorPage.single([scan(id: 'b')])),
      ];
      container.listen(offsiteHistoryNotifierProvider, (_, _) {});
      final notifier = container.read(offsiteHistoryNotifierProvider.notifier);
      await pumpEventQueue();

      await Future.wait([notifier.loadMore(), notifier.loadMore()]);

      expect(repository.myRequestsCalls, [
        (status: null, cursor: null),
        (status: null, cursor: 'c2'),
      ]);
      final state = container.read(offsiteHistoryNotifierProvider);
      expect(state.visible.map((r) => r.id), ['a', 'b']);
      expect(state.requests.valueOrNull!.hasMore, isFalse);
    });

    test('another status starts its own list from its first page', () async {
      container.listen(offsiteHistoryNotifierProvider, (_, _) {});
      final notifier = container.read(offsiteHistoryNotifierProvider.notifier);
      await pumpEventQueue();

      notifier.selectFilter(TimeCorrectionStatus.rejected);
      await pumpEventQueue();

      expect(repository.myRequestsCalls.last, (
        status: TimeCorrectionStatus.rejected,
        cursor: null,
      ));
    });
  });

  group('review fixes', () {
    const notLinked = Failure.validation(
      message: 'no employee',
      code: 'EMPLOYEE_NOT_FOUND',
    );

    testWidgets('a withdrawn request\'s steps end with "cancelled"', (
      tester,
    ) async {
      repository.detailResults = [
        Result.success(scan(status: TimeCorrectionStatus.cancelled)),
      ];
      await open(tester);

      expect(find.text(en.timeCorrectionStatusCancelled), findsWidgets);
      expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
    });

    testWidgets('no staff record: "not linked", no Retry', (tester) async {
      repository.detailResults = [const Result.failure(notLinked)];
      await open(tester);

      expect(find.text(en.offsiteHistoryLoadFailed), findsNothing);
      expect(find.text(en.retry), findsNothing);
    });

    testWidgets('the page\'s own load failed: says so, not the list row as if '
        'it were current', (tester) async {
      repository.detailResults = [
        const Result.failure(Failure.network(message: 'offline')),
      ];
      await open(tester, initial: scan());

      expect(find.text(en.offsiteHistoryLoadFailed), findsOneWidget);
      expect(find.text(en.retry), findsOneWidget);
    });

    test('a second cancel while one is on its way tells nothing (never a '
        '"cancelled" the server did not give)', () async {
      final container = ProviderContainer(
        overrides: [offsiteRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      repository
        ..detailResults = [Result.success(scan())]
        ..cancelResult = const Result.failure(
          Failure.validation(message: OffsiteErrorCode.tokenCannotCancel),
        );
      final provider = offsiteDetailNotifierProvider('off-1');
      container.listen(provider, (_, _) {});
      await container.read(provider.future);
      final notifier = container.read(provider.notifier);

      final first = notifier.cancel();
      final second = await notifier.cancel();
      final firstResult = await first;

      expect(second, isNull);
      expect(firstResult!.isFailure, isTrue);
      expect(repository.cancelled, ['off-1']);
    });

    test('a cancel from the list reads today again (#41\'s card)', () async {
      final attendance = FakeAttendanceRepository();
      final container = ProviderContainer(
        overrides: [
          offsiteRepositoryProvider.overrideWithValue(repository),
          attendanceRepositoryProvider.overrideWithValue(attendance),
          punchLocationSourceProvider.overrideWithValue(
            FakePunchLocationSource(),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.listen(attendanceNotifierProvider, (_, _) {});
      container.listen(offsiteHistoryNotifierProvider, (_, _) {});
      await pumpEventQueue();
      final before = attendance.todayCalls;

      await container
          .read(offsiteHistoryNotifierProvider.notifier)
          .cancel(scan());

      expect(attendance.todayCalls, greaterThan(before));
    });

    test('a failed refresh keeps the rows already shown', () async {
      final container = ProviderContainer(
        overrides: [offsiteRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      repository.mineResult = Result.success([scan(id: 'a')]);
      container.listen(offsiteHistoryNotifierProvider, (_, _) {});
      await pumpEventQueue();
      repository.myRequestsPages = [
        const Result.failure(Failure.network(message: 'offline')),
      ];

      final failure = await container
          .read(offsiteHistoryNotifierProvider.notifier)
          .refresh();

      expect(failure, isNotNull);
      final state = container.read(offsiteHistoryNotifierProvider);
      expect(state.visible.map((r) => r.id), ['a']);
    });

    testWidgets('the list asks for the next page on scroll, not as soon as '
        'a page lands', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      repository.myRequestsPages = [
        for (var p = 0; p < 5; p++)
          Result.success(
            CursorPage(
              items: [for (var i = 0; i < 20; i++) scan(id: 'p$p-$i')],
              nextCursor: 'c$p',
              hasMore: true,
            ),
          ),
      ];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [offsiteRepositoryProvider.overrideWithValue(repository)],
          child: const MaterialApp(
            locale: Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(body: OffsiteRequestsTab()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(repository.myRequestsCalls, hasLength(1));

      await tester.drag(find.byType(ListView), const Offset(0, -20000));
      await tester.pumpAndSettle();
      expect(repository.myRequestsCalls, hasLength(2));
    });

    testWidgets('"My requests" opened with nothing under it: back goes home, '
        'no error', (tester) async {
      final router = GoRouter(
        initialLocation: AppRoutes.myRequests,
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (_, _) => const Scaffold(body: Text('HOME')),
          ),
          GoRoute(
            path: AppRoutes.myRequests,
            builder: (_, _) => const MyRequestsPage(),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [offsiteRepositoryProvider.overrideWithValue(repository)],
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('HOME'), findsOneWidget);
    });
  });
}
