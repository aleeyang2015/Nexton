import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/salary_history/domain/entities/payslip_pdf.dart';
import 'package:next_on/features/salary_history/domain/entities/payslip_record.dart';
import 'package:next_on/features/salary_history/presentation/pages/salary_history_page.dart';
import 'package:next_on/features/salary_history/presentation/services/payslip_pdf_saver.dart';
import 'package:next_on/features/salary_history/salary_history_providers.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';
import 'package:next_on/l10n/generated/app_localizations_en.dart';
import 'package:next_on/l10n/generated/app_localizations_lo.dart';

import '../../support/salary_test_doubles.dart';

/// What the salary list shows for the payslips the server sends.
void main() {
  final en = AppLocalizationsEn();
  final lo = AppLocalizationsLo();
  late FakeSalaryRepository repository;
  late FakePayslipPdfSaver saver;

  // September: paid on 5 October. October: approved, money not sent yet.
  final september = samplePayslipRecord(
    id: 'p-sep',
    periodMonth: 9,
    paidAt: DateTime(2026, 10, 5, 10),
    createdAt: DateTime(2026, 10, 1, 9),
  );
  final october = samplePayslipRecord(
    id: 'p-oct',
    periodMonth: 10,
    status: PayslipRunStatus.approved,
    paymentStatus: PayslipPaymentStatus.pending,
    paid: false,
    netSalary: 7000000,
    createdAt: DateTime(2026, 11, 1, 9),
  );

  setUp(() {
    repository = FakeSalaryRepository()
      ..myPayslipsResult = Result.success([october, september])
      ..pdfResult = Result.success(
        PayslipPdf(bytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2d])),
      );
    saver = FakePayslipPdfSaver();
  });

  Future<void> pumpPage(WidgetTester tester, {String locale = 'en'}) async {
    // Wide enough for the test font, which is far wider than a real one.
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          salaryRepositoryProvider.overrideWithValue(repository),
          payslipPdfSaverProvider.overrideWithValue(saver),
        ],
        child: MaterialApp(
          locale: Locale(locale),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const SalaryHistoryPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Opens the inline totals of the [n]th card.
  Future<void> expand(WidgetTester tester, [int n = 0]) async {
    await tester.tap(find.byIcon(Icons.keyboard_arrow_down).at(n));
    await tester.pumpAndSettle();
  }

  group('the month', () {
    testWidgets('comes from the pay period', (tester) async {
      await pumpPage(tester);

      expect(find.text('October 2026'), findsOneWidget);
      expect(find.text('September 2026'), findsOneWidget);
    });

    testWidgets('comes from the pay period, in Lao', (tester) async {
      await pumpPage(tester, locale: 'lo');

      expect(find.text('ຕຸລາ 2026'), findsOneWidget);
      expect(find.text('ກັນຍາ 2026'), findsOneWidget);
    });

    testWidgets('October\'s payslip, made on 1 November, is October: no '
        'November anywhere', (tester) async {
      await pumpPage(tester);

      expect(find.textContaining('November'), findsNothing);
      // The summary card is the newest pay month, the first row sent.
      expect(
        find.text('${en.salaryNetSalaryLabel} • October 2026'),
        findsOneWidget,
      );
    });

    testWidgets('a payslip with no period is titled "Payslip", with no '
        'month made up for it', (tester) async {
      repository.myPayslipsResult = Result.success([
        samplePayslipRecord(periodYear: null, periodMonth: null, paid: false),
      ]);

      await pumpPage(tester);

      expect(find.text(en.payslipDetailTitle), findsOneWidget);
      expect(
        find.text('${en.salaryNetSalaryLabel} • ${en.payslipDetailTitle}'),
        findsOneWidget,
      );
      // It was made on 1 November 2026; that is not shown as its month.
      expect(find.textContaining('November'), findsNothing);
      expect(find.textContaining('October'), findsNothing);
      expect(find.textContaining('/2026'), findsNothing);
      expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
    });

    testWidgets('in Lao a payslip with no period is "ໃບເງິນເດືອນ"', (
      tester,
    ) async {
      repository.myPayslipsResult = Result.success([
        samplePayslipRecord(periodYear: null, periodMonth: null),
      ]);

      await pumpPage(tester, locale: 'lo');

      expect(find.text('ໃບເງິນເດືອນ'), findsOneWidget);
    });
  });

  group('paid on', () {
    testWidgets('a paid payslip shows the date the server says it was paid',
        (tester) async {
      await pumpPage(tester);

      expect(find.text('${en.salaryPaidOnLabel} 05/10/2026'), findsOneWidget);
    });

    testWidgets('a failed payment shows no paid date, whatever date came '
        'with it', (tester) async {
      repository.myPayslipsResult = Result.success([
        samplePayslipRecord(
          paymentStatus: PayslipPaymentStatus.failed,
          paidAt: DateTime(2026, 11, 5),
        ),
      ]);

      await pumpPage(tester);

      expect(find.textContaining(en.salaryPaidOnLabel), findsNothing);
      expect(find.text(en.salaryPaymentFailed), findsNWidgets(2));
    });

    testWidgets('an approved payslip shows no paid date', (tester) async {
      repository.myPayslipsResult = Result.success([october]);

      await pumpPage(tester);

      expect(find.textContaining(en.salaryPaidOnLabel), findsNothing);
      // Not the day it was made, either.
      expect(find.textContaining('01/11/2026'), findsNothing);
    });
  });

  group('status', () {
    testWidgets('approved and paid, each said once per row; no "Pending"', (
      tester,
    ) async {
      await pumpPage(tester);

      // The summary card (October, approved) and October's row.
      expect(find.text(en.salaryStatusApproved), findsNWidgets(2));
      // The Paid chip and September's row.
      expect(find.text(en.salaryFilterPaid), findsNWidgets(2));
      expect(find.text('Pending'), findsNothing);
    });

    testWidgets('in Lao: ອະນຸມັດແລ້ວ and ຈ່າຍແລ້ວ', (tester) async {
      await pumpPage(tester, locale: 'lo');

      expect(find.text('ອະນຸມັດແລ້ວ'), findsNWidgets(2));
      expect(find.text('ຈ່າຍແລ້ວ'), findsNWidgets(2));
      expect(find.text(lo.salaryFilterAll), findsOneWidget);
    });

    testWidgets('a failed payment has the red pill, and the open row says '
        'to contact HR', (tester) async {
      repository.myPayslipsResult = Result.success([
        samplePayslipRecord(
          id: 'p-failed',
          status: PayslipRunStatus.paid,
          paymentStatus: PayslipPaymentStatus.failed,
          paid: false,
        ),
      ]);
      await pumpPage(tester);

      // Summary card and row.
      expect(find.text(en.salaryPaymentFailed), findsNWidgets(2));
      // It is not also called Paid (the chip is the only "Paid").
      expect(find.text(en.salaryFilterPaid), findsOneWidget);
      expect(find.text(en.salaryPaymentFailedContactHr), findsNothing);

      await expand(tester);

      expect(find.text(en.salaryPaymentFailedContactHr), findsOneWidget);
    });

    testWidgets('in Lao the failed pill and the contact line', (tester) async {
      repository.myPayslipsResult = Result.success([
        samplePayslipRecord(
          paymentStatus: PayslipPaymentStatus.failed,
          paid: false,
        ),
      ]);
      await pumpPage(tester, locale: 'lo');
      await expand(tester);

      expect(find.text('ໂອນເງິນບໍ່ສຳເລັດ'), findsNWidgets(2));
      expect(
        find.text('ການໂອນເງິນບໍ່ສຳເລັດ, ກະລຸນາຕິດຕໍ່ຝ່າຍບຸກຄະລາກອນ'),
        findsOneWidget,
      );
    });

    testWidgets('a payslip whose payment is fine has no contact line', (
      tester,
    ) async {
      await pumpPage(tester);
      await expand(tester);

      expect(find.text(en.salaryPaymentFailedContactHr), findsNothing);
    });

    testWidgets('a status the App does not know gets no pill, not a guess', (
      tester,
    ) async {
      repository.myPayslipsResult = Result.success([
        samplePayslipRecord(
          status: PayslipRunStatus.unknown,
          paymentStatus: PayslipPaymentStatus.unknown,
          paid: false,
        ),
      ]);

      await pumpPage(tester);

      expect(find.text(en.salaryStatusApproved), findsNothing);
      // Only the chip.
      expect(find.text(en.salaryFilterPaid), findsOneWidget);
      expect(find.text('₭ 7,426,674'), findsNWidgets(2));
    });
  });

  group('the open row', () {
    testWidgets('shows the server\'s six figures, and nothing worked out on '
        'the phone', (tester) async {
      repository.myPayslipsResult = Result.success([september]);
      await pumpPage(tester);
      await expand(tester);

      expect(find.text(en.salaryBaseSalary), findsOneWidget);
      expect(find.text('12,000,000'), findsOneWidget);
      expect(find.text(en.salaryGrossLabel), findsOneWidget);
      expect(find.text('12,800,000'), findsOneWidget);
      expect(find.text(en.salarySocialSecurity), findsOneWidget);
      expect(find.text('- 247,500'), findsOneWidget);
      expect(find.text(en.salaryIncomeTax), findsOneWidget);
      expect(find.text('- 940,249'), findsOneWidget);
      // In English the section and its total row share the word.
      expect(find.text(en.salaryTotalDeductionsLabel), findsNWidgets(2));
      expect(find.text('- 5,373,326'), findsOneWidget);
      // Net: the summary card, the row, and the open row's net box.
      expect(find.text('₭ 7,426,674'), findsNWidgets(3));

      // 12,800,000 - 12,000,000 (the old "allowance") and
      // 5,373,326 - 247,500 - 940,249 (the old "other deductions").
      expect(find.text('800,000'), findsNothing);
      expect(find.text('- 4,185,577'), findsNothing);
      expect(find.textContaining('%'), findsNothing);
    });

    testWidgets('a deduction of zero has no minus in front of it', (
      tester,
    ) async {
      repository.myPayslipsResult = Result.success([
        samplePayslipRecord().withTax(0),
      ]);
      await pumpPage(tester);
      await expand(tester);

      expect(find.text('- 0'), findsNothing);
      expect(find.text('0'), findsWidgets);
    });

    testWidgets('a deduction below zero is shown as the number it is, not '
        'with two minus signs', (tester) async {
      repository.myPayslipsResult = Result.success([
        samplePayslipRecord().withTax(-5000),
      ]);
      await pumpPage(tester);
      await expand(tester);

      expect(find.text('-5,000'), findsOneWidget);
      expect(find.textContaining('- -'), findsNothing);
    });

    testWidgets('half a day of unpaid leave shows as 0.5, under "Unpaid '
        'leave (days)"; whole numbers have no decimals', (tester) async {
      repository.myPayslipsResult = Result.success([
        samplePayslipRecord(
          workDays: 21.5,
          overtimeHours: 2,
          unpaidLeaveDays: 0.5,
        ),
      ]);
      await pumpPage(tester);
      await expand(tester);

      expect(find.text('Unpaid leave (days)'), findsOneWidget);
      expect(find.text('0.5'), findsOneWidget);
      expect(find.text('21.5'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('2.0'), findsNothing);
    });

    testWidgets('in Lao the unpaid-leave box reads ລາພັກບໍ່ໄດ້ຮັບເງິນ (ວັນ)', (
      tester,
    ) async {
      await pumpPage(tester, locale: 'lo');
      await expand(tester);

      expect(find.text('ລາພັກບໍ່ໄດ້ຮັບເງິນ (ວັນ)'), findsOneWidget);
    });

    testWidgets('the PDF is saved under the pay month\'s name', (tester) async {
      repository.myPayslipsResult = Result.success([october]);
      await pumpPage(tester);
      await expand(tester);

      await tester.tap(find.text(en.salaryDownloadPdf));
      await tester.pumpAndSettle();

      expect(repository.pdfIds, ['p-oct']);
      expect(saver.saves.single.fileName, 'payslip-2026-10.pdf');
    });

    testWidgets('with no period the PDF is just "payslip.pdf"', (tester) async {
      repository.myPayslipsResult = Result.success([
        samplePayslipRecord(periodYear: null, periodMonth: null),
      ]);
      await pumpPage(tester);
      await expand(tester);

      await tester.tap(find.text(en.salaryDownloadPdf));
      await tester.pumpAndSettle();

      expect(saver.saves.single.fileName, 'payslip.pdf');
    });
  });

  group('the summary card', () {
    testWidgets('shows who the payslip is for', (tester) async {
      await pumpPage(tester);

      expect(find.text('Sandy Vang • EMP-002 • IT Developer'), findsOneWidget);
    });

    testWidgets('a missing position leaves no stray separator', (tester) async {
      repository.myPayslipsResult = Result.success([
        samplePayslipRecord(positionTitle: null),
      ]);

      await pumpPage(tester);

      expect(find.text('Sandy Vang • EMP-002'), findsOneWidget);
    });

    testWidgets('is the newest pay month whichever chip is on', (tester) async {
      await pumpPage(tester);

      await tester.tap(find.widgetWithText(InkWell, en.salaryFilterPaid).first);
      await tester.pumpAndSettle();

      // October is filtered out of the list but still heads the page.
      expect(
        find.text('${en.salaryNetSalaryLabel} • October 2026'),
        findsOneWidget,
      );
      expect(find.text('October 2026'), findsNothing);
      expect(find.text('September 2026'), findsOneWidget);
    });
  });

  group('nothing to show', () {
    testWidgets('no payslips: "no salary records", not an error', (
      tester,
    ) async {
      repository.myPayslipsResult = const Result.success([]);

      await pumpPage(tester);

      expect(find.text(en.salaryHistoryEmpty), findsOneWidget);
      expect(find.text(en.salaryHistoryLoadFailed), findsNothing);
      expect(find.text(en.retry), findsNothing);
    });

    testWidgets('a company without payroll is told so, with no Retry', (
      tester,
    ) async {
      repository.myPayslipsResult = const Result.failure(
        Failure.validation(
          message: 'payroll is not active',
          code: 'MODULE_NOT_ACTIVE',
        ),
      );

      await pumpPage(tester);

      expect(find.text(en.errorModuleNotActive), findsOneWidget);
      expect(find.text(en.salaryHistoryLoadFailed), findsNothing);
      expect(find.text(en.retry), findsNothing);
    });

    testWidgets('no signal: "could not load" with Retry, and Retry loads', (
      tester,
    ) async {
      repository.myPayslipsResult = const Result.failure(
        Failure.network(message: 'offline'),
      );
      await pumpPage(tester);
      expect(find.text(en.salaryHistoryLoadFailed), findsOneWidget);

      repository.myPayslipsResult = Result.success([september]);
      await tester.tap(find.text(en.retry));
      await tester.pumpAndSettle();

      expect(find.text('September 2026'), findsOneWidget);
    });

    testWidgets('a server error also keeps Retry', (tester) async {
      repository.myPayslipsResult = const Result.failure(
        Failure.server(message: 'boom', statusCode: 500),
      );

      await pumpPage(tester);

      expect(find.text(en.salaryHistoryLoadFailed), findsOneWidget);
      expect(find.text(en.retry), findsOneWidget);
    });
  });
}

extension on PayslipRecord {
  /// This payslip with another income tax figure.
  PayslipRecord withTax(int incomeTax) => PayslipRecord(
    id: id,
    employeeNumber: employeeNumber,
    employeeName: employeeName,
    positionTitle: positionTitle,
    baseSalary: baseSalary,
    totalEarnings: totalEarnings,
    totalDeductions: totalDeductions,
    netSalary: netSalary,
    employeeSs: employeeSs,
    incomeTax: incomeTax,
    workDays: workDays,
    paymentStatus: paymentStatus,
    status: status,
    periodYear: periodYear,
    periodMonth: periodMonth,
    paidAt: paidAt,
  );
}
