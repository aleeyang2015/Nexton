
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:next_on/app/router/app_router.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/salary_history/domain/entities/payslip_record.dart';
import 'package:next_on/features/salary_history/presentation/pages/payslip_detail_page.dart';
import 'package:next_on/features/salary_history/presentation/pages/salary_history_page.dart';
import 'package:next_on/features/salary_history/presentation/pages/payslip_pdf_page.dart';
import 'package:next_on/features/salary_history/presentation/services/payslip_pdf_files.dart';
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
  late FakePayslipPdfFiles files;

  setUp(() {
    repository = FakeSalaryRepository()
      // Only this year has payslips.
      ..myPayslipsByYear = ((year) => Result.success(
        year == now.year ? [listRow, approvedRow] : const <PayslipRecord>[],
      ))
      ..myPayslipResult = Result.success(detailRow)
      ..pdfResult = Result.success(samplePayslipPdf);
    files = FakePayslipPdfFiles();
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
          payslipPdfFilesProvider.overrideWithValue(files),
          fakePayslipPdfView(),
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
      // Headline net on each row — wire value. No top card: nothing from
      // /my/latest here.
      expect(find.text('₭ 7,426,674'), findsNWidgets(2));
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

    Future<void> openRow(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.keyboard_arrow_down).first);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('View payslip (PDF)'));
      await tester.pumpAndSettle();
    }

    testWidgets('the row\'s PDF button opens this payslip\'s PDF inside the '
        'App', (tester) async {
      await pumpPage(tester);
      await openRow(tester);

      await tester.tap(find.text('View payslip (PDF)'));
      await tester.pumpAndSettle();

      expect(find.byType(PayslipPdfPage), findsOneWidget);
      expect(repository.pdfIds, [listRow.id]);
      expect(
        find.text('PDF /tmp/payslips/1/payslip-EMP-002-2026-10.pdf'),
        findsOneWidget,
      );
    });

    testWidgets('a double tap opens one PDF page and sends one request', (
      tester,
    ) async {
      await pumpPage(tester);
      await openRow(tester);

      await tester.tap(find.text('View payslip (PDF)'));
      await tester.tap(find.text('View payslip (PDF)'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Counting the pages hidden under the top one too.
      expect(
        find.byType(PayslipPdfPage, skipOffstage: false),
        findsOneWidget,
      );
      expect(repository.pdfIds, [listRow.id]);
    });

    testWidgets('closing the PDF page deletes its file, and the button opens '
        'it again', (tester) async {
      await pumpPage(tester);
      await openRow(tester);
      await tester.tap(find.text('View payslip (PDF)'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(PayslipPdfPage),
          matching: find.byIcon(Icons.arrow_back_ios),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PayslipPdfPage), findsNothing);
      expect(files.live, isEmpty);
      expect(files.deletes, hasLength(1));

      await tester.tap(find.text('View payslip (PDF)'));
      await tester.pumpAndSettle();
      expect(find.byType(PayslipPdfPage), findsOneWidget);
      expect(repository.pdfIds, [listRow.id, listRow.id]);
    });
  });

  group('the top card', () {
    testWidgets('a tap opens the newest payslip, by its id', (tester) async {
      repository.latestResult = const Result.success(sampleLatestPayslip);
      await pumpPage(tester);

      await tester.tap(find.text('Net Salary • December 2026'));
      await tester.pumpAndSettle();

      expect(find.byType(PayslipDetailPage), findsOneWidget);
      expect(repository.myPayslipIds, ['p-dec']);
    });

    testWidgets('coming back from the payslip does not ask for the newest '
        'payslip again', (tester) async {
      repository.latestResult = const Result.success(sampleLatestPayslip);
      await pumpPage(tester);

      await tester.tap(find.text('Net Salary • December 2026'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(PayslipDetailPage),
          matching: find.byIcon(Icons.arrow_back_ios),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SalaryHistoryPage), findsOneWidget);
      expect(repository.latestCalls, 1);
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

    testWidgets('the PDF icon opens this payslip\'s PDF inside the App', (
      tester,
    ) async {
      await pumpPage(tester);

      await tester.tap(find.text('August ${now.year}'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.picture_as_pdf_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(PayslipPdfPage), findsOneWidget);
      expect(repository.pdfIds, [listRow.id]);
    });

    testWidgets('a PDF that could not be made says so on its page, and Back '
        'returns to the payslip', (tester) async {
      repository.pdfResult = const Result.failure(
        Failure.server(message: 'boom', statusCode: 500),
      );
      await pumpPage(tester);

      await tester.tap(find.text('August ${now.year}'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.picture_as_pdf_outlined));
      await tester.pumpAndSettle();

      expect(
        find.text('Could not make the PDF. Please try again'),
        findsOneWidget,
      );
      expect(files.writes, isEmpty);

      await tester.tap(
        find.descendant(
          of: find.byType(PayslipPdfPage),
          matching: find.byIcon(Icons.arrow_back_ios),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PayslipDetailPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
