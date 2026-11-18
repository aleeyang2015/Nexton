import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/features/auth/presentation/providers/module_access_provider.dart';
import 'package:next_on/features/home/presentation/widgets/home_menu_grid.dart';
import 'package:next_on/features/list/presentation/widgets/list_menu_entries.dart';
import 'package:next_on/features/list/presentation/widgets/list_menu_grid.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';
import 'package:next_on/l10n/generated/app_localizations_en.dart';

import '../../support/approver_access_test_doubles.dart';
import '../../support/test_asset_bundle.dart';

/// The menu shows only what the company has bought (#61).
void main() {
  final en = AppLocalizationsEn();

  Future<List<String>> labels(WidgetTester tester, List<String> modules) async {
    late List<ListMenuEntry> built;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          approverAccessOf(),
          activeModulesProvider.overrideWithValue(modules),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Consumer(
            builder: (context, ref, _) {
              built = buildListMenuEntries(context, ref, en);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    return [for (final e in built) e.label];
  }

  late final coreHrTiles = [
    en.approvalsMenu,
    en.leaveMenu,
    en.leaveHistoryMenu,
    en.otMenu,
    en.forgotClockInMenu,
    en.attMyRequestsMenu,
  ];

  testWidgets('Core HR and Payroll: every tile', (tester) async {
    final shown = await labels(tester, const ['core_hr', 'payroll']);
    expect(shown, containsAll([...coreHrTiles, en.salaryHistoryMenu]));
  });

  testWidgets('no Payroll: no Salary tile, the rest as before', (tester) async {
    final shown = await labels(tester, const ['core_hr']);
    expect(shown, isNot(contains(en.salaryHistoryMenu)));
    expect(shown, containsAll(coreHrTiles));
  });

  testWidgets('no Core HR: none of its tiles (and no Salary: it needs Core '
      'HR)', (tester) async {
    final shown = await labels(tester, const ['payroll']);
    expect(shown, isEmpty);
  });

  testWidgets('nothing bought: an empty menu', (tester) async {
    expect(await labels(tester, const []), isEmpty);
  });

  testWidgets('the home grid counts only the tiles it shows', (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          approverAccessOf(),
          activeModulesProvider.overrideWithValue(const ['core_hr']),
        ],
        child: DefaultAssetBundle(
          bundle: TestAssetBundle(),
          child: MaterialApp(
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const Scaffold(body: HomeMenuGrid()),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text(en.salaryHistoryMenu), findsNothing);
    expect(find.text(en.leaveMenu), findsOneWidget);
    expect(
      tester.widget<ListMenuGrid>(find.byType(ListMenuGrid)).entries,
      hasLength(coreHrTiles.length),
    );
  });
}
