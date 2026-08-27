import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:next_on/app/router/app_router.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/salary_history/domain/entities/payslip.dart';
import 'package:next_on/features/salary_history/domain/repositories/salary_repository.dart';
import 'package:next_on/features/salary_history/presentation/pages/payslip_detail_page.dart';
import 'package:next_on/features/salary_history/presentation/pages/salary_history_page.dart';
import 'package:next_on/features/salary_history/salary_history_providers.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';

class _FakeSalaryRepository implements SalaryRepository {
  final List<Payslip> payslips;

  _FakeSalaryRepository(this.payslips);

  @override
  FutureResult<List<Payslip>> history(int year) async =>
      Result.success(payslips.where((p) => p.year == year).toList());
}

void main() {
  final now = DateTime.now();
  final payslip = Payslip(
    id: '${now.year}-08',
    year: now.year,
    month: 8,
    paidDate: DateTime(now.year, 8, 20),
    status: PayslipStatus.paid,
    employeeName: 'Sandy Vang',
    employeeCode: 'EMP-002',
    position: 'IT Developer',
    department: 'IT Development',
    baseSalary: 12000000,
    allowance: 800000,
    socialSecurity: 247500,
    socialSecurityRate: 0.045,
    incomeTax: 940249,
    otherDeductions: 4185577,
    workingDays: 22,
    overtimeHours: 0,
    paidLeaveDays: 0,
    earnings: const [
      PayslipLine(title: 'Base salary', caption: 'BASIC', amount: 12000000),
    ],
    allowances: const [
      PayslipLine(title: 'Position allowance', caption: 'POS', amount: 300000),
    ],
    attendanceDeductions: const [
      PayslipLine(
        title: 'Late arrival',
        caption: 'LATE',
        amount: -31731,
        icon: PayslipLineIcon.lateArrival,
      ),
    ],
    statutoryDeductions: const [
      PayslipLine(
        title: 'Income tax',
        caption: 'PIT',
        amount: -940249,
        icon: PayslipLineIcon.incomeTax,
      ),
    ],
    taxableIncome: 12552500,
    socialSecurityBase: 270000,
  );

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
          builder: (_, state) =>
              PayslipDetailPage(payslip: state.extra as Payslip),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          salaryRepositoryProvider.overrideWithValue(
            _FakeSalaryRepository([payslip]),
          ),
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

  testWidgets('tapping the card body opens the payslip detail page', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.byType(PayslipDetailPage), findsNothing);

    await tester.tap(find.text('August ${now.year}'));
    await tester.pumpAndSettle();

    expect(find.byType(PayslipDetailPage), findsOneWidget);
    // A label unique to the detail page's totals strip.
    expect(find.text('Gross'), findsOneWidget);
  });

  testWidgets('tapping the chevron expands inline and does not navigate', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
    await tester.pumpAndSettle();

    // Still on the history page: the chevron flipped, no detail page pushed.
    expect(find.byType(PayslipDetailPage), findsNothing);
    expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
    expect(find.text('Gross'), findsNothing);
  });

  testWidgets('the detail page renders the payslip without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: PayslipDetailPage(payslip: payslip),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Payslip – August ${now.year}'), findsOneWidget);
    expect(find.text('EMP-002 · IT Developer · IT Development'), findsOneWidget);
    expect(find.text('SV'), findsOneWidget);
    // Totals strip (no currency mark) and the headline net (K-prefixed).
    expect(find.text('12,800,000'), findsOneWidget);
    expect(find.text('-5,373,326'), findsOneWidget);
    expect(find.text('K 7,426,674'), findsOneWidget);
    // Sections rendered from the line items.
    expect(find.text('Welfare / Allowances'), findsOneWidget);
    expect(find.text('- 940,249'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
