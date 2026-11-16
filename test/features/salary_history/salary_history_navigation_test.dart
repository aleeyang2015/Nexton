import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:next_on/app/router/app_router.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/utils/result.dart';
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

  /// What the single-payslip call returns: the same payslip, with its lines.
  final detailRow = samplePayslipRecord(
    periodYear: now.year,
    periodMonth: 8,
    lines: samplePayslipLines,
    benefits: samplePayslipBenefits,
    deductionItems: samplePayslipDeductionItems,
  );

  late FakeSalaryRepository repository;
  late FakePayslipPdfSaver saver;

  setUp(() {
    repository = FakeSalaryRepository()
      // Only this year has payslips.
      ..myPayslipsByYear = ((year) => Result.success(
        year == now.year ? [listRow, approvedRow] : const <PayslipRecord>[],
      ))
      ..myPayslipResult = Result.success(detailRow)
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
        ...payslipRoutes,
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
    testWidgets('tapping the card body opens the payslip page for that id, '
        'and it loads the lines', (tester) async {
      await pumpPage(tester);

      expect(find.byType(PayslipDetailPage), findsNothing);

      await tester.tap(find.text('August ${now.year}'));
      await tester.pumpAndSettle();

      final page = tester.widget<PayslipDetailPage>(
        find.byType(PayslipDetailPage),
      );
      expect(page.payslipId, listRow.id);
      expect(repository.myPayslipIds, [listRow.id]);
      expect(find.text('Payslip – August ${now.year}'), findsOneWidget);
      // Lines come from the single-payslip call, not the list row.
      expect(find.text('Position allowance'), findsOneWidget);
    });

    testWidgets('the list\'s row shows at once, with a placeholder for the '
        'lines, while the payslip is on its way', (tester) async {
      repository.hangMyPayslip = true;
      await pumpPage(tester);

      await tester.tap(find.text('August ${now.year}'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Payslip – August ${now.year}'), findsOneWidget);
      expect(find.text('₭7,426,674'), findsOneWidget);
      expect(find.text('Position allowance'), findsNothing);
    });

    testWidgets('the page agrees with the row that opened it: an approved '
        'payslip is "Approved" there too, never "Pending"', (tester) async {
      repository.myPayslipResult = Result.success(approvedRow);
      await pumpPage(tester);

      await tester.tap(find.text('September ${now.year}'));
      await tester.pumpAndSettle();

      expect(find.text('Payslip – September ${now.year}'), findsOneWidget);
      // The header line and the pill.
      expect(find.text('Approved'), findsNWidgets(2));
      expect(find.text('Pending'), findsNothing);
    });

    testWidgets('a failed load of the lines shows the error under the row\'s '
        'header, and Retry loads them', (tester) async {
      repository.myPayslipResult = const Result.failure(
        Failure.server(message: 'boom', statusCode: 500),
      );
      await pumpPage(tester);

      await tester.tap(find.text('August ${now.year}'));
      await tester.pumpAndSettle();

      expect(find.text('Unable to load the payslip.'), findsOneWidget);
      // The header and totals still stand — they came with the list row.
      expect(find.text('₭7,426,674'), findsOneWidget);

      repository.myPayslipResult = Result.success(detailRow);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(repository.myPayslipIds, [listRow.id, listRow.id]);
      expect(find.text('Position allowance'), findsOneWidget);
    });

    testWidgets('a payslip that is not there (404) is "not available", '
        'with Back and no Retry', (tester) async {
      repository.myPayslipResult = const Result.failure(
        Failure.network(message: 'not found', statusCode: 404),
      );
      await pumpPage(tester);

      await tester.tap(find.text('August ${now.year}'));
      await tester.pumpAndSettle();

      expect(find.text('This payslip is not available'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
      // The row's figures are not shown under it.
      expect(find.text('₭7,426,674'), findsNothing);

      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(PayslipDetailPage), findsNothing);
      expect(find.byType(SalaryHistoryPage), findsOneWidget);
    });

    testWidgets('the save icon fetches this payslip\'s PDF, named for its pay '
        'month', (tester) async {
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
  });
}
