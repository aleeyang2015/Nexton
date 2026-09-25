import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/features/home/presentation/widgets/home_menu_grid.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('lays out the menu and counts its entries on a small phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('lo'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: HomeMenuGrid(),
            ),
          ),
        ),
      ),
    );

    final lo = lookupAppLocalizations(const Locale('lo'));
    expect(tester.takeException(), isNull);
    expect(find.text(lo.navList), findsOneWidget);
    expect(find.text(lo.menuItemCount(5)), findsOneWidget);
    expect(find.text(lo.salaryHistoryMenu), findsOneWidget);
  });
}
