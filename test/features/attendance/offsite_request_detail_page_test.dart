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
}
