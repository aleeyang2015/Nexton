import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:next_on/app/router/app_router.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/network/api_error_mapper.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/core/widgets/app_toast.dart';
import 'package:next_on/core/widgets/shimmer_box.dart';
import 'package:next_on/features/overtime/domain/entities/ot_page.dart';
import 'package:next_on/features/overtime/domain/entities/ot_request.dart';
import 'package:next_on/features/overtime/overtime_providers.dart';
import 'package:next_on/features/overtime/presentation/pages/ot_list_page.dart';
import 'package:next_on/features/overtime/presentation/pages/ot_request_detail_page.dart';
import 'package:next_on/features/overtime/presentation/widgets/ot_request_row.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';
import 'package:next_on/l10n/generated/app_localizations_en.dart';
import 'package:next_on/l10n/generated/app_localizations_lo.dart';

import '../../support/overtime_test_doubles.dart';

/// The OT list page: rows with their badges, the filters, and what it says
/// when there is nothing to show.
void main() {
  final en = AppLocalizationsEn();
  final lo = AppLocalizationsLo();
  late FakeOtRepository repository;

  setUp(() => repository = FakeOtRepository());

  void serve(List<OtRequest> rows, {int totalPages = 1}) =>
      repository.myRequestsAnswer = (call) => Result.success(
        OtPage(items: rows, page: call.page, totalPages: totalPages),
      );

  Future<void> pumpPage(
    WidgetTester tester, {
    String locale = 'en',
    bool settle = true,
  }) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [otRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: AppRoutes.overtime,
            routes: overtimeRoutes,
          ),
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          locale: Locale(locale),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }
  }

  group('rows', () {
    testWidgets('date, window and pill; newest first as the server sent them',
        (tester) async {
      serve([
        sampleOt('ot-14', workDate: DateTime(2026, 11, 14)),
        sampleOt(
          'ot-07',
          workDate: DateTime(2026, 11, 7),
          start: '08:00',
          end: '12:00',
          status: OtStatus.approved,
          announcementId: 'post-1',
          didNotCome: true,
        ),
      ]);

      await pumpPage(tester, locale: 'lo');

      expect(find.text('ໂອທີ'), findsOneWidget);
      expect(find.text('14/11/2026'), findsOneWidget);
      expect(find.text('18:00–20:00'), findsOneWidget);
      expect(find.text('07/11/2026'), findsOneWidget);
      expect(find.text('08:00–12:00'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('14/11/2026')).dy,
        lessThan(tester.getTopLeft(find.text('07/11/2026')).dy),
      );
      // The chip and the row's pill.
      expect(find.text('ອະນຸມັດແລ້ວ'), findsNWidgets(2));
      expect(find.text('ຈາກປະກາດ'), findsOneWidget);
      expect(find.text('ບໍ່ໄດ້ມາ'), findsOneWidget);
    });

    testWidgets('past midnight: (ມື້ຖັດໄປ)', (tester) async {
      serve([sampleOt('ot-n', start: '22:00', end: '02:00', endsNextDay: true)]);

      await pumpPage(tester, locale: 'lo');

      expect(find.text('22:00–02:00 (ມື້ຖັດໄປ)'), findsOneWidget);
    });

    testWidgets('no badges on a plain request', (tester) async {
      serve([sampleOt('ot-1')]);

      await pumpPage(tester);

      expect(find.text(en.otFromPost), findsNothing);
      expect(find.text(en.otDidNotCome), findsNothing);
    });

    Future<void> openAndComeBack(WidgetTester tester, String date) async {
      await tester.tap(find.text(date).first);
      await tester.pumpAndSettle();
      expect(find.byType(OtRequestDetailPage), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(OtRequestDetailPage),
          matching: find.byIcon(Icons.arrow_back_ios),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(OtListPage), findsOneWidget);
    }

    testWidgets('a tap opens the request\'s page; coming back asks for '
        'nothing', (tester) async {
      serve([sampleOt('ot-1')]);
      await pumpPage(tester);
      final before = repository.listCalls.length;

      await openAndComeBack(tester, '14/11/2026');

      expect(repository.requestIds, ['ot-1']);
      expect(repository.listCalls, hasLength(before));
    });

    testWidgets('a request that changed meanwhile shows changed in the list '
        'when coming back, and the pages loaded stay', (tester) async {
      repository.myRequestsAnswer = (call) => pagedOt(call, total: 45);
      repository.requestAnswer = (id) =>
          Result.success(sampleOt(id, status: OtStatus.cancelled));
      await pumpPage(tester);
      await tester.drag(find.byType(ListView).last, const Offset(0, -5000));
      await tester.pumpAndSettle();
      final pages = repository.listCalls.length;
      await tester.drag(find.byType(ListView).last, const Offset(0, 5000));
      await tester.pumpAndSettle();

      await openAndComeBack(tester, '14/11/2026');

      expect(repository.listCalls, hasLength(pages));
      expect(find.byType(OtRequestRow, skipOffstage: false), findsNWidgets(45));
      // The chip, and the row that changed.
      expect(find.text(en.leaveStatusCancelled), findsNWidgets(2));
    });

    testWidgets('a request that is gone (404) leaves the list', (tester) async {
      serve([sampleOt('ot-1'), sampleOt('ot-2', workDate: DateTime(2026, 11, 2))]);
      repository.requestAnswer = (_) => const Result.failure(
        Failure.network(message: 'not found', statusCode: 404),
      );
      await pumpPage(tester);

      await tester.tap(find.text('14/11/2026'));
      await tester.pumpAndSettle();

      expect(find.byType(OtListPage), findsOneWidget);
      expect(find.text('14/11/2026'), findsNothing);
      expect(find.text('02/11/2026'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('a double tap opens one page', (tester) async {
      serve([sampleOt('ot-1')]);
      await pumpPage(tester);

      await tester.tap(find.text('14/11/2026'));
      await tester.tap(find.text('14/11/2026'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(
        find.byType(OtRequestDetailPage, skipOffstage: false),
        findsOneWidget,
      );
    });
  });

  group('filters', () {
    testWidgets('a chip asks with its status; All asks with none', (
      tester,
    ) async {
      await pumpPage(tester);

      await tester.tap(find.text(en.leaveStatusRejected));
      await tester.pumpAndSettle();
      expect(repository.listCalls.last.status, OtStatus.rejected);

      await tester.tap(find.text(en.leaveFilterAll));
      await tester.pumpAndSettle();
      expect(repository.listCalls.last.status, isNull);
    });

    testWidgets('the month button opens the picker; a month asks for it, '
        'All months clears it', (tester) async {
      await pumpPage(tester);
      expect(find.text(en.otAllMonths), findsOneWidget);

      await tester.tap(find.text(en.otAllMonths));
      await tester.pumpAndSettle();
      expect(find.text(en.otPickMonth), findsOneWidget);
      final year = DateTime.now().year;
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mar'));
      await tester.pumpAndSettle();

      expect(repository.listCalls.last.month, DateTime(year - 1, 3));
      expect(find.text('March ${year - 1}'), findsOneWidget);

      await tester.tap(find.text('March ${year - 1}'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, en.otAllMonths));
      await tester.pumpAndSettle();

      expect(repository.listCalls.last.month, isNull);
      expect(find.text(en.otAllMonths), findsOneWidget);
    });

    testWidgets('Cancel in the picker changes nothing', (tester) async {
      await pumpPage(tester);
      final calls = repository.listCalls.length;

      await tester.tap(find.text(en.otAllMonths));
      await tester.pumpAndSettle();
      await tester.tap(find.text(en.cancel));
      await tester.pumpAndSettle();

      expect(repository.listCalls, hasLength(calls));
    });
  });

  group('nothing to show', () {
    testWidgets('a shimmer while the first page loads', (tester) async {
      repository.holdMyRequests = Completer<void>();

      await pumpPage(tester, settle: false);

      expect(find.byType(ShimmerBox), findsWidgets);
    });

    testWidgets('no requests: ຍັງບໍ່ມີຄຳຂໍໂອທີ', (tester) async {
      await pumpPage(tester, locale: 'lo');

      expect(find.text('ຍັງບໍ່ມີຄຳຂໍໂອທີ'), findsOneWidget);
    });

    testWidgets('no employee linked: #4\'s text, no Retry, no endless spinner',
        (tester) async {
      repository.myRequestsAnswer = (_) => const Result.failure(
        Failure.validation(
          message: 'employee not found',
          code: ApiErrorCodes.employeeNotFound,
        ),
      );

      await pumpPage(tester, locale: 'lo');

      expect(find.text(lo.ruleEmployeeNotFound), findsOneWidget);
      expect(find.text(lo.retry), findsNothing);
      expect(find.byType(ShimmerBox), findsNothing);
    });

    testWidgets('no signal: "could not load OT" with Retry, and Retry loads',
        (tester) async {
      repository.myRequestsAnswer = (_) =>
          const Result.failure(Failure.network(message: 'offline'));

      await pumpPage(tester, locale: 'lo');
      expect(find.text('ບໍ່ສາມາດໂຫຼດຂໍ້ມູນໂອທີໄດ້.'), findsOneWidget);

      serve([sampleOt('ot-1')]);
      await tester.tap(find.text(lo.retry));
      await tester.pumpAndSettle();

      expect(find.text('14/11/2026'), findsOneWidget);
    });
  });

  group('pull to refresh that fails', () {
    testWidgets('keeps the rows and says it could not load', (tester) async {
      serve([sampleOt('ot-1')]);
      await pumpPage(tester);
      repository.myRequestsAnswer = (_) =>
          const Result.failure(Failure.network(message: 'offline'));

      await tester.timedDrag(
        find.byType(RefreshIndicator),
        const Offset(0, 600),
        const Duration(milliseconds: 500),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('14/11/2026'), findsOneWidget);
      expect(find.text(en.otListLoadFailed), findsOneWidget);
      expect(find.text(en.retry), findsNothing);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });
  });

  group('the month picker', () {
    testWidgets('the year stays within 2000 to 2200', (tester) async {
      await pumpPage(tester);
      await tester.tap(find.text(en.otAllMonths));
      await tester.pumpAndSettle();

      for (var i = 0; i < 60; i++) {
        final back = tester.widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.chevron_left),
        );
        if (back.onPressed == null) break;
        await tester.tap(find.byIcon(Icons.chevron_left));
        await tester.pump();
      }

      expect(find.text('2000'), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.chevron_left))
            .onPressed,
        isNull,
      );
    });
  });

  group('more pages', () {
    testWidgets('scrolling to the end loads the next page', (tester) async {
      repository.myRequestsAnswer = (call) => pagedOt(call, total: 45);

      await pumpPage(tester);
      await tester.drag(find.byType(ListView).last, const Offset(0, -5000));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).last, const Offset(0, -5000));
      await tester.pumpAndSettle();

      expect(repository.listCalls.map((c) => c.page), containsAllInOrder([1, 2, 3]));
      expect(find.byType(OtRequestRow, skipOffstage: false), findsNWidgets(45));
    });

    testWidgets('pull to refresh asks for page 1 again', (tester) async {
      serve([sampleOt('ot-1')]);
      await pumpPage(tester);
      final before = repository.listCalls.length;

      await tester.timedDrag(
        find.byType(RefreshIndicator),
        // Past a quarter of the list's height: what arms the refresh.
        const Offset(0, 600),
        const Duration(milliseconds: 500),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(repository.listCalls.length, before + 1);
      expect(repository.listCalls.last.page, 1);
    });
  });
}
