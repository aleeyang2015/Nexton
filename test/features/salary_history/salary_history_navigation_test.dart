import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:next_on/app/router/app_router.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/salary_history/domain/entities/payslip.dart';
import 'package:next_on/features/salary_history/domain/entities/payslip_record.dart';
import 'package:next_on/features/salary_history/domain/entities/payslip_pdf.dart';
import 'package:next_on/features/salary_history/presentation/pages/payslip_detail_page.dart';
import 'package:next_on/features/salary_history/presentation/pages/salary_history_page.dart';
import 'package:next_on/features/salary_history/presentation/services/payslip_pdf_saver.dart';
import 'package:next_on/features/salary_history/salary_history_providers.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';

import '../../support/salary_test_doubles.dart';

void main() {
  final now = DateTime.now();

  /// What the list call returns: the server's rows, totals only. August is
  /// paid; September is approved and not paid yet.
  final listRow = samplePayslipRecord(periodYear: now.year, periodMonth: 8);
  final approvedRow = samplePayslipRecord(
    id: 'approved-id',
    periodYear: now.year,
    periodMonth: 9,
    status: PayslipRunStatus.approved,
    paymentStatus: PayslipPaymentStatus.pending,
    paid: false,
  );

  /// What the detail call returns (the detail page still reads the old
  /// entity).
  final detailRow = samplePayslip(year: now.year);

  late FakeSalaryRepository repository;
  late FakePayslipPdfSaver saver;

  setUp(() {
    repository = FakeSalaryRepository()
      // Only this year has payslips.
      ..myPayslipsByYear = ((year) => Result.success(
        year == now.year ? [listRow, approvedRow] : const <PayslipRecord>[],
      ))
      ..detailResult = Result.success(detailRow)
      ..pdfResult = Result.success(
        PayslipPdf(bytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2d])),
      );
    saver = FakePayslipPdfSaver();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: AppRoutes.salaryHistory,
      routes: [
        GoRoute(
          path: AppRoutes.salaryHistory,
          builder: (_, __) => const SalaryHistoryPage(),
        ),
        GoRoute(
          path: AppRoutes.payslipDetail,
          builder: (_, state) {
            final row = state.extra as PayslipRecord;
            return PayslipDetailPage(payslipId: row.id, listRow: row);
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          salaryRepositoryProvider.overrideWithValue(repository),
          payslipPdfSaverProvider.overrideWithValue(saver),
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
  }

  group('history list', () {
    testWidgets('loads the current year and renders the backend figures', (
      tester,
    ) async {
      await pumpPage(tester);

      expect(repository.myPayslipsYears, [now.year]);
      // Headline net on the summary card and on each row — wire value.
      expect(find.text('₭ 7,426,674'), findsNWidgets(3));
      expect(find.text('August ${now.year}'), findsOneWidget);
      expect(find.text('September ${now.year}'), findsOneWidget);
    });

    testWidgets('stepping the year back asks the API for that year', (
      tester,
    ) async {
      await pumpPage(tester);

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      expect(repository.myPayslipsYears, [now.year, now.year - 1]);
      expect(find.text('No salary records'), findsOneWidget);
    });

    testWidgets('the Paid chip keeps the paid payslips, with no request; '
        'there is no Pending chip', (tester) async {
      await pumpPage(tester);
      expect(find.text('Pending'), findsNothing);

      // The chips sit above the list, so the chip is the first "Paid"
      // InkWell in tree order; the status pills come later.
      await tester.tap(find.widgetWithText(InkWell, 'Paid').first);
      await tester.pumpAndSettle();
      expect(find.text('August ${now.year}'), findsOneWidget);
      expect(find.text('September ${now.year}'), findsNothing);

      await tester.tap(find.widgetWithText(InkWell, 'All').first);
      await tester.pumpAndSettle();
      expect(find.text('September ${now.year}'), findsOneWidget);

      // One call served every chip — filtering is local.
      expect(repository.myPayslipsYears, [now.year]);
    });

    testWidgets('a failed load shows the error state and retries', (
      tester,
    ) async {
      repository.myPayslipsByYear = (_) =>
          const Result.failure(Failure.network(message: 'offline'));
      await pumpPage(tester);

      expect(find.text('Unable to load salary records.'), findsOneWidget);

      repository.myPayslipsByYear = (_) => Result.success([listRow]);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('August ${now.year}'), findsOneWidget);
    });

    testWidgets('tapping the chevron expands inline and does not navigate', (
      tester,
    ) async {
      await pumpPage(tester);

      await tester.tap(find.byIcon(Icons.keyboard_arrow_down).first);
      await tester.pumpAndSettle();

      // Still on the history page: the chevron flipped, no detail page pushed.
      expect(find.byType(PayslipDetailPage), findsNothing);
      expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
      // The inline breakdown reads the wire aggregates.
      expect(find.text('Unpaid leave (days)'), findsOneWidget);
      expect(find.text('22'), findsOneWidget);
    });

    testWidgets('the inline download button fetches this payslip\'s PDF', (
      tester,
    ) async {
      await pumpPage(tester);

      await tester.tap(find.byIcon(Icons.keyboard_arrow_down).first);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Download Payslip (PDF)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Download Payslip (PDF)'));
      await tester.pumpAndSettle();

      expect(repository.pdfIds, [listRow.id]);
      expect(saver.saves, hasLength(1));
      expect(saver.saves.single.fileName, 'payslip-${now.year}-08.pdf');
      expect(saver.saves.single.bytes.length, 5);
    });
  });

  group('detail page', () {
    testWidgets('tapping the card body opens the detail for that payslip id', (
      tester,
    ) async {
      await pumpPage(tester);

      expect(find.byType(PayslipDetailPage), findsNothing);

      await tester.tap(find.text('August ${now.year}'));
      await tester.pumpAndSettle();

      expect(find.byType(PayslipDetailPage), findsOneWidget);
      expect(repository.detailIds, [listRow.id]);
      // A label unique to the detail page's totals strip.
      expect(find.text('Gross'), findsOneWidget);
      // Sections come from the detail call, not the list row.
      expect(find.text('Welfare / Allowances'), findsOneWidget);
      expect(find.text('Position allowance'), findsOneWidget);
    });

    testWidgets('shows a placeholder, and no figures, while the payslip is '
        'on its way', (tester) async {
      repository.hangDetail = true;
      await pumpPage(tester);

      await tester.tap(find.text('August ${now.year}'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(PayslipDetailPage), findsOneWidget);
      expect(find.text('Payslip'), findsOneWidget);
      expect(find.text('₭7,426,674'), findsNothing);
      expect(find.text('Welfare / Allowances'), findsNothing);
    });

    testWidgets('a failed detail call shows the error state and retries', (
      tester,
    ) async {
      repository.detailResult = const Result.failure(
        Failure.server(message: 'boom', statusCode: 500),
      );
      await pumpPage(tester);

      await tester.tap(find.text('August ${now.year}'));
      await tester.pumpAndSettle();

      expect(find.text('Unable to load the payslip.'), findsOneWidget);

      repository.detailResult = Result.success(detailRow);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(repository.detailIds, [listRow.id, listRow.id]);
      expect(find.text('Welfare / Allowances'), findsOneWidget);
      expect(find.text('₭7,426,674'), findsOneWidget);
    });

    testWidgets('the page agrees with the row that opened it: an approved '
        'payslip is "Approved" there too, never "Pending"', (tester) async {
      await pumpPage(tester);

      await tester.tap(find.text('September ${now.year}'));
      await tester.pumpAndSettle();

      expect(find.text('Payslip – September ${now.year}'), findsOneWidget);
      // The header line and the pill.
      expect(find.text('Approved'), findsNWidgets(2));
      expect(find.text('Pending'), findsNothing);
    });

    testWidgets('October\'s payslip, made on 1 November, opens as October, '
        'and its PDF is named for October', (tester) async {
      final october = samplePayslipRecord(
        id: 'p-oct',
        periodYear: now.year,
        periodMonth: 10,
      );
      repository
        ..myPayslipsByYear = ((_) => Result.success([october]))
        // The old entity behind the page says November (from created_at).
        ..detailResult = Result.success(
          samplePayslip(id: 'p-oct', year: now.year, month: 11),
        );
      await pumpPage(tester);

      await tester.tap(find.text('October ${now.year}'));
      await tester.pumpAndSettle();

      expect(find.text('Payslip – October ${now.year}'), findsOneWidget);
      expect(find.textContaining('November'), findsNothing);

      await tester.tap(find.byIcon(Icons.save_alt));
      await tester.pumpAndSettle();
      expect(saver.saves.single.fileName, 'payslip-${now.year}-10.pdf');
    });

    testWidgets('a failed payment says so on the page too, in place of '
        '"Pending" or a paid date', (tester) async {
      final failed = samplePayslipRecord(
        id: 'p-failed',
        periodYear: now.year,
        periodMonth: 7,
        paymentStatus: PayslipPaymentStatus.failed,
      );
      repository
        ..myPayslipsByYear = ((_) => Result.success([failed]))
        ..detailResult = Result.success(
          samplePayslip(
            id: 'p-failed',
            year: now.year,
            month: 7,
            status: PayslipStatus.pending,
          ),
        );
      await pumpPage(tester);

      await tester.tap(find.text('July ${now.year}'));
      await tester.pumpAndSettle();

      expect(find.byType(PayslipDetailPage), findsOneWidget);
      expect(find.text('Payment failed'), findsNWidgets(2));
      expect(find.text('Pending'), findsNothing);
      expect(find.textContaining('Paid on'), findsNothing);
    });

    testWidgets('a payslip that is not there (404) has no Retry', (
      tester,
    ) async {
      repository.detailResult = const Result.failure(
        Failure.network(message: 'not found', statusCode: 404),
      );
      await pumpPage(tester);

      await tester.tap(find.text('August ${now.year}'));
      await tester.pumpAndSettle();

      expect(find.text('Unable to load the payslip.'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('the save icon fetches this payslip\'s PDF', (tester) async {
      await pumpPage(tester);

      await tester.tap(find.text('August ${now.year}'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.save_alt));
      await tester.pumpAndSettle();

      expect(repository.pdfIds, [listRow.id]);
      expect(saver.saves.single.fileName, 'payslip-${now.year}-08.pdf');
    });

    testWidgets('a failed PDF download leaves the page in place', (
      tester,
    ) async {
      repository.pdfResult = const Result.failure(
        Failure.network(message: 'offline'),
      );
      await pumpPage(tester);

      await tester.tap(find.text('August ${now.year}'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.save_alt));
      await tester.pumpAndSettle();

      expect(saver.saves, isEmpty);
      expect(find.byIcon(Icons.save_alt), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders the payslip without overflow', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            salaryRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: PayslipDetailPage(payslipId: detailRow.id, initial: detailRow),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Payslip – August ${now.year}'), findsOneWidget);
      expect(find.text('EMP-002'), findsOneWidget);
      expect(find.text('•  IT Developer'), findsOneWidget);
      expect(find.text('•  IT Development'), findsOneWidget);
      expect(find.text('SV'), findsOneWidget);
      // Totals strip (no currency mark) and the headline net (K-prefixed) —
      // straight from the wire.
      expect(find.text('12,800,000'), findsOneWidget);
      expect(find.text('-5,373,326'), findsOneWidget);
      expect(find.text('₭7,426,674'), findsOneWidget);
      // Sections rendered from the detail call's line items.
      expect(find.text('Welfare / Allowances'), findsOneWidget);
      expect(find.text('- 940,249'), findsOneWidget);
      expect(find.text('LATE · 33 minutes'), findsOneWidget);
      // No SS base on the wire → no SS base row.
      expect(find.text('Social security base'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
