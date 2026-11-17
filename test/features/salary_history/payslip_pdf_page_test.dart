import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/network/api_error_mapper.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/core/widgets/app_toast.dart';
import 'package:next_on/features/salary_history/presentation/pages/payslip_pdf_page.dart';
import 'package:next_on/features/salary_history/presentation/services/payslip_pdf_files.dart';
import 'package:next_on/features/salary_history/salary_history_providers.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';
import 'package:next_on/l10n/generated/app_localizations_en.dart';
import 'package:next_on/l10n/generated/app_localizations_lo.dart';

import '../../support/salary_test_doubles.dart';

/// The payslip's PDF inside the App: making it, showing it, sharing it, and
/// what the page says when there is none.
void main() {
  final en = AppLocalizationsEn();
  final lo = AppLocalizationsLo();
  late FakeSalaryRepository repository;
  late FakePayslipPdfFiles files;

  setUp(() {
    repository = FakeSalaryRepository()
      ..pdfResult = Result.success(samplePayslipPdf);
    files = FakePayslipPdfFiles();
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    String locale = 'en',
    bool settle = true,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          salaryRepositoryProvider.overrideWithValue(repository),
          payslipPdfFilesProvider.overrideWithValue(files),
          fakePayslipPdfView(),
        ],
        child: MaterialApp(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          locale: Locale(locale),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const PayslipPdfPage(payslipId: 'p-oct'),
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  void answer(Failure failure) => repository.pdfResult = Result.failure(failure);

  group('while the PDF is made', () {
    testWidgets('a spinner and "Making the PDF…", and no Share', (tester) async {
      repository.holdPdf = Completer<void>();

      await pumpPage(tester, settle: false);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text(en.payslipPdfLoading), findsOneWidget);
      expect(find.byIcon(Icons.ios_share), findsNothing);
    });

    testWidgets('in Lao: ກຳລັງສ້າງ PDF…', (tester) async {
      repository.holdPdf = Completer<void>();

      await pumpPage(tester, locale: 'lo', settle: false);

      expect(find.text('ກຳລັງສ້າງ PDF…'), findsOneWidget);
      expect(find.text(lo.payslipPdfTitle), findsOneWidget);
    });
  });

  group('once loaded', () {
    testWidgets('shows the PDF file and a Share button', (tester) async {
      await pumpPage(tester);

      expect(repository.pdfIds, ['p-oct']);
      expect(
        find.text('PDF /tmp/payslips/1/payslip-EMP-002-2026-10.pdf'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.ios_share), findsOneWidget);
      expect(find.text(en.payslipPdfTitle), findsOneWidget);
    });

    testWidgets('Share hands the file to the share sheet, from the button',
        (tester) async {
      await pumpPage(tester);

      await tester.tap(find.byIcon(Icons.ios_share));
      await tester.pumpAndSettle();

      final share = files.shares.single;
      expect(share.path, '/tmp/payslips/1/payslip-EMP-002-2026-10.pdf');
      // Where the iPad's share sheet points from: the button itself.
      expect(share.origin, isNotNull);
      expect(share.origin!.isEmpty, isFalse);
    });

    testWidgets('a share sheet that could not open says so', (tester) async {
      files.shareFails = true;
      await pumpPage(tester);

      await tester.tap(find.byIcon(Icons.ios_share));
      await tester.pump();

      expect(find.text(en.payslipPdfShareFailed), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('leaving the page deletes the file', (tester) async {
      await pumpPage(tester);

      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pumpAndSettle();

      expect(files.live, isEmpty);
      expect(files.deletes, hasLength(1));
    });
  });

  group('when there is no PDF', () {
    testWidgets('500: "Could not make the PDF. Please try again", with Retry; '
        'Retry asks again', (tester) async {
      answer(const Failure.server(message: 'boom', statusCode: 500));
      await pumpPage(tester);

      expect(find.text(en.payslipPdfMakeFailed), findsOneWidget);
      expect(find.byIcon(Icons.ios_share), findsNothing);
      expect(files.writes, isEmpty);

      repository.pdfResult = Result.success(samplePayslipPdf);
      await tester.tap(find.text(en.retry));
      await tester.pumpAndSettle();

      expect(repository.pdfIds, ['p-oct', 'p-oct']);
      expect(find.byIcon(Icons.ios_share), findsOneWidget);
    });

    testWidgets('500 in Lao: ສ້າງໄຟລ໌ PDF ບໍ່ສຳເລັດ, ກະລຸນາລອງໃໝ່', (
      tester,
    ) async {
      answer(const Failure.server(message: 'boom', statusCode: 500));
      await pumpPage(tester, locale: 'lo');

      expect(find.text('ສ້າງໄຟລ໌ PDF ບໍ່ສຳເລັດ, ກະລຸນາລອງໃໝ່'), findsOneWidget);
    });

    testWidgets('404: "This payslip is not available", no Retry', (
      tester,
    ) async {
      answer(
        const Failure.network(
          message: 'Payslip not found',
          statusCode: 404,
          errorCode: 'NOT_FOUND',
        ),
      );
      await pumpPage(tester);

      expect(find.text(en.payslipNotAvailable), findsOneWidget);
      expect(find.text(en.retry), findsNothing);
    });

    testWidgets('no payroll: its own text, no Retry', (tester) async {
      answer(
        const Failure.validation(
          message: 'off',
          code: ApiErrorCodes.moduleNotActive,
        ),
      );
      await pumpPage(tester);

      expect(find.text(en.payslipPdfMakeFailed), findsNothing);
      expect(find.text(en.retry), findsNothing);
    });

    testWidgets('no signal: says so, with Retry', (tester) async {
      answer(
        const Failure.network(
          message: 'No internet connection',
          errorCode: ApiErrorCodes.noInternet,
        ),
      );
      await pumpPage(tester);

      expect(find.text(en.noInternetConnection), findsOneWidget);
      expect(find.text(en.retry), findsOneWidget);
    });

    testWidgets('a 200 that was not a PDF is never shown as one: "could not '
        'make", with Retry', (tester) async {
      answer(const Failure.validation(message: 'salaryPdfInvalid'));
      await pumpPage(tester);

      expect(find.textContaining('PDF /tmp'), findsNothing);
      expect(find.text(en.payslipPdfMakeFailed), findsOneWidget);
      expect(find.text(en.retry), findsOneWidget);
    });
  });
}
