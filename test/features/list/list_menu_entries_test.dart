import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:next_on/core/modules/app_modules.dart';
import 'package:next_on/app/router/app_router.dart';
import 'package:next_on/features/list/presentation/widgets/list_menu_entries.dart';
import 'package:next_on/features/list/presentation/widgets/list_menu_grid.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';
import 'package:next_on/l10n/generated/app_localizations_lo.dart';

import '../../support/approver_access_test_doubles.dart';

/// The menu the list tab and the home screen share.
void main() {
  final lo = AppLocalizationsLo();

  Future<List<ListMenuEntry>> entries(WidgetTester tester) async {
    late List<ListMenuEntry> built;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          approverAccessOf(),
          activeModulesProvider.overrideWithValue(const ['core_hr', 'payroll']),
        ],
        child: MaterialApp(
          locale: const Locale('lo'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Consumer(
            builder: (context, ref, _) {
              built = buildListMenuEntries(context, ref, lo);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    return built;
  }

  testWidgets('the OT tile is ໂອທີ, right after leave history, with its own '
      'icon (not "forgot clock-in"\'s)', (tester) async {
    final list = await entries(tester);
    final labels = list.map((e) => e.label).toList();
    final ot = list.singleWhere((e) => e.label == 'ໂອທີ');

    expect(labels.indexOf('ໂອທີ'), labels.indexOf(lo.leaveHistoryMenu) + 1);
    expect(ot.icon, Icons.work_history_outlined);
    expect(
      list.where((e) => e.icon == Icons.work_history_outlined),
      hasLength(1),
    );
  });

  testWidgets('tapping it opens /overtime', (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Consumer(
            builder: (context, ref, _) => Scaffold(
              body: ListMenuGrid(
                entries: buildListMenuEntries(context, ref, lo),
              ),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.overtime,
          builder: (_, _) => const Text('OT PAGE'),
        ),
      ],
    );
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          approverAccessOf(),
          activeModulesProvider.overrideWithValue(const ['core_hr', 'payroll']),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('lo'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('ໂອທີ'));
    await tester.pumpAndSettle();

    expect(find.text('OT PAGE'), findsOneWidget);
  });
}
