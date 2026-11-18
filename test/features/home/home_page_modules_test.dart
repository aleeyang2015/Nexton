import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:next_on/app/router/app_router.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/features/auth/presentation/providers/module_access_provider.dart';
import 'package:next_on/core/network/api_error_mapper.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/attendance/presentation/widgets/attendance_status_card.dart';
import 'package:next_on/features/home/presentation/pages/home_page.dart';
import 'package:next_on/features/home/presentation/widgets/attendance_history_summary.dart';
import 'package:next_on/features/profile/profile_providers.dart';
import 'package:next_on/features/salary_history/presentation/pages/salary_history_page.dart';
import 'package:next_on/features/salary_history/salary_history_providers.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';
import 'package:next_on/l10n/generated/app_localizations_en.dart';

import '../../support/approver_access_test_doubles.dart';
import '../../support/profile_test_doubles.dart';
import '../../support/salary_test_doubles.dart';
import '../../support/test_asset_bundle.dart';

/// What a company without a module sees (#61).
void main() {
  final en = AppLocalizationsEn();

  testWidgets('no Core HR: no clock card, no month summary; "not turned on" '
      'said once, and no empty menu', (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeModulesProvider.overrideWithValue(const []),
          approverAccessOf(),
          // As the real server answers a company without Core HR.
          profileRepositoryProvider.overrideWithValue(
            FakeProfileRepository()
              ..profile = const Result.failure(
                Failure.validation(
                  message: "Module 'core_hr' is not active",
                  code: ApiErrorCodes.moduleNotActive,
                ),
              ),
          ),
        ],
        child: DefaultAssetBundle(
          bundle: TestAssetBundle(),
          child: MaterialApp(
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const HomePage(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(AttendanceStatusCard), findsNothing);
    expect(find.byType(AttendanceHistorySummary), findsNothing);
    // Said once, by the header; no empty menu under it.
    expect(find.text(en.errorModuleNotActive), findsOneWidget);
    expect(find.text(en.leaveMenu), findsNothing);
    expect(find.text(en.homeServicesTitle), findsNothing);
  });

  testWidgets('a deep link into Salary for a company without Payroll: the '
      '"not turned on" text, not a crash or a blank page', (tester) async {
    final repository = FakeSalaryRepository()
      ..myPayslipsResult = const Result.failure(
        Failure.validation(
          message: "Module 'payroll' is not active for this subscription",
          code: ApiErrorCodes.moduleNotActive,
        ),
      );
    final router = GoRouter(
      initialLocation: AppRoutes.salaryHistory,
      routes: [
        GoRoute(
          path: AppRoutes.salaryHistory,
          builder: (_, _) => const SalaryHistoryPage(),
        ),
      ],
    );
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
    await tester.pumpAndSettle();

    expect(find.text(en.errorModuleNotActive), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
