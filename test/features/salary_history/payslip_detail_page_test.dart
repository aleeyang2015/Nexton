import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/salary_history/domain/entities/payslip_pdf.dart';
import 'package:next_on/features/salary_history/domain/entities/payslip_record.dart';
import 'package:next_on/features/salary_history/presentation/pages/payslip_detail_page.dart';
import 'package:next_on/features/salary_history/presentation/services/payslip_pdf_saver.dart';
import 'package:next_on/features/salary_history/salary_history_providers.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';
import 'package:next_on/l10n/generated/app_localizations_en.dart';

import '../../support/salary_test_doubles.dart';

/// The payslip page, opened by id: what it shows for the payslip the server
/// sends, and what it says when there is none to show.
void main() {
  final en = AppLocalizationsEn();
  late FakeSalaryRepository repository;
  late FakePayslipPdfSaver saver;

  /// October 2026, paid on 5 November, with the sample lines. Its totals
  /// (12,800,000 / 5,373,326 / 7,426,674) are not what the lines add up to.
  PayslipRecord fullPayslip({
    PayslipRunStatus status = PayslipRunStatus.paid,
    PayslipPaymentStatus paymentStatus = PayslipPaymentStatus.paid,
    bool paid = true,
    int? periodYear = 2026,
    int? periodMonth = 10,
    List<PayslipRecordLine> lines = samplePayslipLines,
  }) => samplePayslipRecord(
    id: 'p-oct',
    status: status,
    paymentStatus: paymentStatus,
    paid: paid,
    periodYear: periodYear,
    periodMonth: periodMonth,
    lines: lines,
    benefits: samplePayslipBenefits,
    deductionItems: samplePayslipDeductionItems,
  );

  setUp(() {
    repository = FakeSalaryRepository()
      ..myPayslipResult = Result.success(fullPayslip())
      ..pdfResult = Result.success(
        PayslipPdf(bytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2d])),
      );
    saver = FakePayslipPdfSaver();
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    String locale = 'en',
    PayslipRecord? listRow,
    bool settle = true,
  }) async {
    // Wide and tall: the test font is far wider than a real one, and every
    // row should be laid out.
    tester.view.physicalSize = const Size(900, 4200);
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
          home: PayslipDetailPage(payslipId: 'p-oct', listRow: listRow),
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  /// The texts on the page, top to bottom.
  List<String> textsInOrder(WidgetTester tester) {
    final found = <(double, String)>[];
    for (final element in find.byType(Text).evaluate()) {
      final text = (element.widget as Text).data;
      if (text == null) continue;
      found.add((tester.getTopLeft(find.byWidget(element.widget)).dy, text));
    }
    found.sort((a, b) => a.$1.compareTo(b.$1));
    return [for (final (_, text) in found) text];
  }

  group('opened by id', () {
    testWidgets('loads that payslip and shows it', (tester) async {
      await pumpPage(tester);

      expect(repository.myPayslipIds, ['p-oct']);
      expect(find.text('Payslip – October 2026'), findsOneWidget);
      expect(find.text('Sandy Vang'), findsOneWidget);
    });

    testWidgets('a placeholder shows while it loads, and no figures', (
      tester,
    ) async {
      repository.hangMyPayslip = true;

      await pumpPage(tester, settle: false);

      expect(find.text(en.payslipDetailTitle), findsOneWidget);
      expect(find.textContaining('7,426,674'), findsNothing);
      expect(find.text(en.retry), findsNothing);
    });

    testWidgets('leaving while it loads throws nothing', (tester) async {
      repository.myPayslipDelay = const Duration(milliseconds: 300);
      await pumpPage(tester, settle: false);

      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
    });

    testWidgets('with the list\'s row handed in, its header and totals show '
        'at once and the lines arrive after', (tester) async {
      repository.myPayslipDelay = const Duration(milliseconds: 300);
      final row = samplePayslipRecord(id: 'p-oct');

      await pumpPage(tester, listRow: row, settle: false);

      expect(find.text('Payslip – October 2026'), findsOneWidget);
      expect(find.text('₭7,426,674'), findsOneWidget);
      expect(find.text(en.payslipLineOvertime), findsNothing);

      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      expect(find.text(en.payslipLineOvertime), findsOneWidget);
    });
  });

  group('the header', () {
    testWidgets('the month is the pay period, in Lao too; never the month '
        'the payslip was made in', (tester) async {
      await pumpPage(tester, locale: 'lo');

      expect(find.text('ໃບເງິນເດືອນ – ຕຸລາ 2026'), findsOneWidget);
      // Made on 1 November.
      expect(find.textContaining('ພະຈິກ'), findsNothing);
    });

    testWidgets('with no period it is just "Payslip"', (tester) async {
      repository.myPayslipResult = Result.success(
        fullPayslip(periodYear: null, periodMonth: null),
      );

      await pumpPage(tester);

      // The title bar's text.
      expect(find.text(en.payslipDetailTitle), findsOneWidget);
      expect(find.textContaining('November'), findsNothing);
      expect(find.textContaining('October'), findsNothing);
    });

    testWidgets('a paid payslip shows the date it was paid, and "Paid"', (
      tester,
    ) async {
      await pumpPage(tester);

      expect(find.text('${en.salaryPaidOnLabel} 05/11/2026'), findsOneWidget);
      expect(find.text(en.salaryFilterPaid), findsOneWidget);
    });

    testWidgets('an approved payslip shows "Approved" and no paid date', (
      tester,
    ) async {
      repository.myPayslipResult = Result.success(
        fullPayslip(
          status: PayslipRunStatus.approved,
          paymentStatus: PayslipPaymentStatus.pending,
          paid: false,
        ),
      );

      await pumpPage(tester);

      // Under the title, and on the pill.
      expect(find.text(en.salaryStatusApproved), findsNWidgets(2));
      expect(find.textContaining(en.salaryPaidOnLabel), findsNothing);
      expect(find.text('Pending'), findsNothing);
    });

    testWidgets('a failed payment says so in red, with the contact-HR line, '
        'and no paid date', (tester) async {
      repository.myPayslipResult = Result.success(
        fullPayslip(paymentStatus: PayslipPaymentStatus.failed),
      );

      await pumpPage(tester);

      expect(find.text(en.salaryPaymentFailed), findsNWidgets(2));
      expect(find.text(en.salaryPaymentFailedContactHr), findsOneWidget);
      expect(find.textContaining(en.salaryPaidOnLabel), findsNothing);
      expect(find.text(en.salaryFilterPaid), findsNothing);
    });

    testWidgets('a payslip that is fine has no contact-HR line', (
      tester,
    ) async {
      await pumpPage(tester);

      expect(find.text(en.salaryPaymentFailedContactHr), findsNothing);
    });

    testWidgets('the employee card shows the number, position and '
        'department', (tester) async {
      await pumpPage(tester);

      expect(find.text('EMP-002'), findsOneWidget);
      expect(find.text('•  IT Developer'), findsOneWidget);
      expect(find.text('•  IT Development'), findsOneWidget);
      expect(find.text('SV'), findsOneWidget);
    });

    testWidgets('a part the server did not send is left out, with no stray '
        'dot', (tester) async {
      repository.myPayslipResult = Result.success(
        samplePayslipRecord(id: 'p-oct', positionTitle: null),
      );

      await pumpPage(tester);

      expect(find.text('•  IT Development'), findsOneWidget);
      expect(find.textContaining('•  IT Developer'), findsNothing);
      expect(find.text('•  '), findsNothing);
    });
  });

  group('the totals', () {
    testWidgets('are the server\'s three figures, not the lines added up', (
      tester,
    ) async {
      await pumpPage(tester);

      expect(find.text('12,800,000'), findsOneWidget);
      expect(find.text('-5,373,326'), findsOneWidget);
      // The strip and the footer.
      expect(find.text('7,426,674'), findsOneWidget);
      expect(find.text('₭7,426,674'), findsOneWidget);

      // What the earning lines and benefits would come to
      // (12,000,000 + 162,259 + 300,000 + 26), and the deductions
      // (68,910 + 96,154 + 247,500 + 940,249 + 500,000 + 100,000).
      expect(find.textContaining('12,462,285'), findsNothing);
      expect(find.textContaining('1,952,813'), findsNothing);
    });

    testWidgets('the footer shows the taxable income and the net, and '
        'nothing else: no employer share, no SS base, no rate', (
      tester,
    ) async {
      await pumpPage(tester);

      expect(find.text(en.salaryTaxableIncomeLabel), findsOneWidget);
      expect(find.text('12,552,500'), findsOneWidget);
      // The employer's social security (270,000) is the company's, not hers.
      expect(find.textContaining('270,000'), findsNothing);
      expect(find.textContaining('employer'), findsNothing);
      expect(find.textContaining('%'), findsNothing);
    });

    testWidgets('in Lao the taxable-income label has no English in it', (
      tester,
    ) async {
      await pumpPage(tester, locale: 'lo');

      expect(find.text('ລາຍໄດ້ຄິດອາກອນ'), findsOneWidget);
      expect(find.textContaining('taxable income'), findsNothing);
    });
  });

  group('the lines', () {
    testWidgets('are in the four groups, in order, each row under the right '
        'heading', (tester) async {
      await pumpPage(tester);

      final texts = textsInOrder(tester);
      int at(String text) {
        final index = texts.indexOf(text);
        expect(index, isNonNegative, reason: '"$text" is on the page');
        return index;
      }

      final earnings = at(en.salaryIncomeSection);
      final attendance = at(en.payslipSectionAttendance);
      final statutory = at(en.payslipSectionStatutory);
      final other = at(en.payslipSectionOther);
      expect(earnings < attendance, isTrue);
      expect(attendance < statutory, isTrue);
      expect(statutory < other, isTrue);

      bool between(String text, int from, int to) =>
          at(text) > from && at(text) < to;

      // Earnings: base, OT, then the benefits.
      expect(between(en.salaryBaseSalary, earnings, attendance), isTrue);
      expect(between(en.payslipLineOvertime, earnings, attendance), isTrue);
      expect(between('Position allowance', earnings, attendance), isTrue);
      expect(at(en.salaryBaseSalary) < at(en.payslipLineOvertime), isTrue);
      expect(at(en.payslipLineOvertime) < at('Position allowance'), isTrue);

      // Attendance.
      for (final title in [
        en.payslipLineLate,
        en.payslipLineAbsentLate,
        en.payslipLineEarlyOut,
        en.payslipLineMissedPart,
        en.payslipLineAbsence,
        en.payslipLineUnpaidLeave,
      ]) {
        expect(between(title, attendance, statutory), isTrue, reason: title);
      }

      // By law.
      expect(between(en.salarySocialSecurity, statutory, other), isTrue);
      expect(between(en.salaryIncomeTax, statutory, other), isTrue);

      // Other: the loan, then the deduction item.
      expect(at(en.payslipLineLoan) > other, isTrue);
      expect(at('ພັກວຽກ') > at(en.payslipLineLoan), isTrue);
    });

    testWidgets('there is no allowances section and no merged "statutory / '
        'other"', (tester) async {
      await pumpPage(tester);

      expect(find.textContaining('Welfare'), findsNothing);
      expect(find.textContaining('Statutory / Other'), findsNothing);
    });

    testWidgets('the attendance lines of zero are shown, with captions like '
        '"0 min" and "0 times"', (tester) async {
      await pumpPage(tester);

      // Early out and missed part, at zero minutes.
      expect(find.text('0 min'), findsNWidgets(2));
      // Late past the limit and absence, at zero times.
      expect(find.text('0 times'), findsNWidgets(2));
      // Their amounts are a plain 0.
      expect(find.text('0'), findsNWidgets(4));
    });

    testWidgets('in Lao the zero lines read 0 ນາທີ and 0 ເທື່ອ, and OT is '
        'ຄ່າລ່ວງເວລາ (ໂອທີ) with its hours', (tester) async {
      await pumpPage(tester, locale: 'lo');

      expect(find.text('0 ນາທີ'), findsNWidgets(2));
      expect(find.text('0 ເທື່ອ'), findsNWidgets(2));
      expect(find.text('ຄ່າລ່ວງເວລາ (ໂອທີ)'), findsOneWidget);
      expect(find.text('2.25 ຊົ່ວໂມງ'), findsOneWidget);
      expect(find.text('1 ຊມ 35 ນາທີ'), findsOneWidget);
      expect(find.text('0.5 ວັນ'), findsOneWidget);
      expect(find.text('ລາພັກບໍ່ໄດ້ຮັບເງິນ'), findsOneWidget);
    });

    testWidgets('a caption never carries the line\'s code', (tester) async {
      await pumpPage(tester);

      expect(find.textContaining('LATE'), findsNothing);
      expect(find.textContaining('PIT'), findsNothing);
      expect(find.textContaining('·'), findsNothing);
    });

    testWidgets('each amount is the line\'s own: deductions with a minus, '
        'earnings with a plus', (tester) async {
      await pumpPage(tester);

      expect(find.text('+ 12,000,000'), findsOneWidget);
      expect(find.text('+ 162,259'), findsOneWidget);
      // The late line was 95 minutes; its amount is what the server took.
      expect(find.text('- 68,910'), findsOneWidget);
      expect(find.text('- 96,154'), findsOneWidget);
      expect(find.text('- 247,500'), findsOneWidget);
      expect(find.text('- 940,249'), findsOneWidget);
      expect(find.text('- 500,000'), findsOneWidget);
      expect(find.text('- 100,000'), findsOneWidget);
    });

    testWidgets('a benefit with decimals is rounded to whole kip as the '
        'server rounds it', (tester) async {
      await pumpPage(tester);

      // 25.5 → 26.
      expect(find.text('+ 26'), findsOneWidget);
      expect(find.textContaining('25.5'), findsNothing);
    });

    testWidgets('a loan shows its own name as the caption', (tester) async {
      await pumpPage(tester);

      expect(find.text(en.payslipLineLoan), findsOneWidget);
      expect(find.text('Loan: motorbike'), findsOneWidget);
    });

    testWidgets('a company\'s own allowance shows under the name the server '
        'sent, among the earnings', (tester) async {
      repository.myPayslipResult = Result.success(
        fullPayslip(
          lines: const [
            PayslipRecordLine(
              id: 'l-shift',
              componentCode: 'SHIFT-ALW',
              componentName: 'Shift allowance',
              type: PayslipLineType.earning,
              category: 'variable',
              amount: 150000,
            ),
          ],
        ),
      );

      await pumpPage(tester);

      expect(find.text('Shift allowance'), findsOneWidget);
      expect(find.text('+ 150,000'), findsOneWidget);
    });

    testWidgets('a line whose kind the App does not know is still shown, '
        'under the server\'s name', (tester) async {
      repository.myPayslipResult = Result.success(
        fullPayslip(
          lines: const [
            PayslipRecordLine(
              id: 'l-odd',
              componentCode: 'MYSTERY',
              componentName: 'Something new',
              amount: 4200,
            ),
          ],
        ),
      );

      await pumpPage(tester);

      expect(find.text('Something new'), findsOneWidget);
      expect(find.textContaining('4,200'), findsOneWidget);
    });

    testWidgets('a payslip with no lines shows its totals and no empty '
        'headings', (tester) async {
      repository.myPayslipResult = Result.success(
        samplePayslipRecord(id: 'p-oct'),
      );

      await pumpPage(tester);

      expect(find.text('12,800,000'), findsOneWidget);
      expect(find.text(en.payslipSectionAttendance), findsNothing);
      expect(find.text(en.payslipSectionStatutory), findsNothing);
      expect(find.text(en.payslipSectionOther), findsNothing);
    });
  });

  group('when there is no payslip to show', () {
    testWidgets('404: "This payslip is not available" with Back, no Retry', (
      tester,
    ) async {
      repository.myPayslipResult = const Result.failure(
        Failure.network(message: 'not found', statusCode: 404),
      );

      await pumpPage(tester);

      expect(find.text(en.payslipNotAvailable), findsOneWidget);
      expect(find.text(en.back), findsOneWidget);
      expect(find.text(en.retry), findsNothing);
    });

    testWidgets('404 in Lao: ໃບເງິນເດືອນນີ້ບໍ່ມີແລ້ວ and ກັບຄືນ', (tester) async {
      repository.myPayslipResult = const Result.failure(
        Failure.network(message: 'not found', statusCode: 404),
      );

      await pumpPage(tester, locale: 'lo');

      expect(find.text('ໃບເງິນເດືອນນີ້ບໍ່ມີແລ້ວ'), findsOneWidget);
      expect(find.text('ກັບຄືນ'), findsOneWidget);
    });

    testWidgets('404 hides the list\'s row too: it is not a payslip that can '
        'be opened', (tester) async {
      repository.myPayslipResult = const Result.failure(
        Failure.network(message: 'not found', statusCode: 404),
      );

      await pumpPage(tester, listRow: samplePayslipRecord(id: 'p-oct'));

      expect(find.text(en.payslipNotAvailable), findsOneWidget);
      expect(find.textContaining('7,426,674'), findsNothing);
    });

    testWidgets('a server error: "could not load" with Retry, and Retry '
        'loads it', (tester) async {
      repository.myPayslipResult = const Result.failure(
        Failure.server(message: 'boom', statusCode: 500),
      );
      await pumpPage(tester);

      expect(find.text(en.payslipDetailLoadFailed), findsOneWidget);
      expect(find.text(en.back), findsNothing);

      repository.myPayslipResult = Result.success(fullPayslip());
      await tester.tap(find.text(en.retry));
      await tester.pumpAndSettle();

      expect(repository.myPayslipIds, ['p-oct', 'p-oct']);
      expect(find.text('Payslip – October 2026'), findsOneWidget);
    });

    testWidgets('no signal: the same, with Retry', (tester) async {
      repository.myPayslipResult = const Result.failure(
        Failure.network(message: 'offline'),
      );

      await pumpPage(tester);

      expect(find.text(en.payslipDetailLoadFailed), findsOneWidget);
      expect(find.text(en.retry), findsOneWidget);
    });

    testWidgets('a retry under way shows a spinner, not the first-load '
        'placeholder and not the Retry link', (tester) async {
      repository.myPayslipResult = const Result.failure(
        Failure.server(message: 'boom', statusCode: 500),
      );
      await pumpPage(tester);

      repository.myPayslipDelay = const Duration(milliseconds: 300);
      await tester.tap(find.text(en.retry));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text(en.retry), findsNothing);

      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(repository.myPayslipIds, hasLength(2));
    });

    testWidgets('a company without payroll is told so, with no Retry', (
      tester,
    ) async {
      repository.myPayslipResult = const Result.failure(
        Failure.validation(
          message: 'payroll is not active',
          code: 'MODULE_NOT_ACTIVE',
        ),
      );

      await pumpPage(tester);

      expect(find.text(en.errorModuleNotActive), findsOneWidget);
      expect(find.text(en.retry), findsNothing);
      expect(find.text(en.payslipDetailLoadFailed), findsNothing);
    });

    testWidgets('a payslip the reader refused shows "could not load", not '
        'the reader\'s English reason', (tester) async {
      repository.myPayslipResult = const Result.failure(
        Failure.validation(message: 'A payslip without an id'),
      );

      await pumpPage(tester);

      expect(find.text(en.payslipDetailLoadFailed), findsOneWidget);
      expect(find.textContaining('without an id'), findsNothing);
    });
  });

  group('the PDF', () {
    testWidgets('is saved under the pay month\'s name', (tester) async {
      await pumpPage(tester);

      await tester.tap(find.byIcon(Icons.save_alt));
      await tester.pumpAndSettle();

      expect(repository.pdfIds, ['p-oct']);
      expect(saver.saves.single.fileName, 'payslip-2026-10.pdf');
    });
  });
}
