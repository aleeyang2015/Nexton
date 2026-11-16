import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:next_on/app/router/app_router.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/salary_history/presentation/pages/payslip_detail_page.dart';
import 'package:next_on/features/salary_history/salary_history_providers.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';

import '../support/salary_test_doubles.dart';

/// The payslip page is opened by the payslip's id, so the salary list, a
/// link and a push can all reach it.
void main() {
  late FakeSalaryRepository repository;
  late GoRouter router;

  setUp(() {
    repository = FakeSalaryRepository()
      ..myPayslipResult = Result.success(samplePayslipRecord(id: 'abc'));
    router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SizedBox.shrink()),
        ...payslipRoutes,
      ],
    );
  });

  Future<void> open(
    WidgetTester tester,
    String location, {
    Object? extra,
  }) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [salaryRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
        ),
      ),
    );
    router.push(location, extra: extra);
    await tester.pumpAndSettle();
  }

  PayslipDetailPage page(WidgetTester tester) =>
      tester.widget<PayslipDetailPage>(find.byType(PayslipDetailPage));

  test('the location is built from the id', () {
    expect(AppRoutes.payslip('abc'), '/salary-history/payslip/abc');
  });

  test('an id with a character a path cannot hold is escaped', () {
    expect(AppRoutes.payslip('a/b'), '/salary-history/payslip/a%2Fb');
  });

  testWidgets('/salary-history/payslip/abc builds the page with id abc, and '
      'it loads that payslip', (tester) async {
    await open(tester, '/salary-history/payslip/abc');

    expect(page(tester).payslipId, 'abc');
    expect(page(tester).listRow, isNull);
    expect(repository.myPayslipIds, ['abc']);
  });

  testWidgets('with no extra the page opens: nothing falls through to "not '
      'found"', (tester) async {
    await open(tester, '/salary-history/payslip/abc');

    expect(find.byType(PayslipDetailPage), findsOneWidget);
    expect(find.text('Sandy Vang'), findsOneWidget);
  });

  testWidgets('the list\'s row handed in as extra is used for the first '
      'paint', (tester) async {
    final row = samplePayslipRecord(id: 'abc');

    await open(tester, AppRoutes.payslip('abc'), extra: row);

    expect(page(tester).listRow, row);
  });

  testWidgets('an extra that is another payslip, or not a payslip, is '
      'ignored', (tester) async {
    await open(
      tester,
      AppRoutes.payslip('abc'),
      extra: samplePayslipRecord(id: 'someone-elses'),
    );
    expect(page(tester).listRow, isNull);
  });

  testWidgets('an id with odd characters reaches the page as it was', (
    tester,
  ) async {
    repository.myPayslipResult = Result.success(
      samplePayslipRecord(id: 'a/b c'),
    );

    await open(tester, AppRoutes.payslip('a/b c'));

    expect(page(tester).payslipId, 'a/b c');
    expect(repository.myPayslipIds, ['a/b c']);
  });

  testWidgets('opened with nothing underneath (a link or a push), Back goes '
      'to the salary list and throws nothing', (tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final direct = GoRouter(
      initialLocation: AppRoutes.payslip('abc'),
      routes: [
        GoRoute(
          path: AppRoutes.salaryHistory,
          builder: (_, _) => const Scaffold(body: Text('the salary list')),
        ),
        ...payslipRoutes,
      ],
    );
    repository.myPayslipResult = const Result.failure(
      Failure.network(message: 'not found', statusCode: 404),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [salaryRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(
          routerConfig: direct,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('the salary list'), findsOneWidget);
  });

  testWidgets('a string extra (the old way of passing an id) is ignored: '
      'the id is the one in the path', (tester) async {
    await open(tester, AppRoutes.payslip('abc'), extra: 'other-id');

    expect(page(tester).payslipId, 'abc');
    expect(repository.myPayslipIds, ['abc']);
  });
}
