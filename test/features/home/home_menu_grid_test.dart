import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/features/home/presentation/widgets/home_menu_grid.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';

import '../../support/approver_access_test_doubles.dart';

void main() {
  Future<void> pumpMenu(WidgetTester tester, {required bool head}) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [approverAccessOf(approverTestUser(head: head))],
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
  }

  testWidgets('plain staff: no Approvals tile, one fewer entry', (
    tester,
  ) async {
    await pumpMenu(tester, head: false);

    final lo = lookupAppLocalizations(const Locale('lo'));
    expect(tester.takeException(), isNull);
    expect(find.text(lo.menuItemCount(7)), findsOneWidget);
    expect(find.text(lo.approvalsMenu), findsNothing);
    expect(find.text(lo.otMenu), findsOneWidget);
  });

  testWidgets('lays out the menu and counts its entries on a small phone '
      '(a department head)', (
    tester,
  ) async {
    await pumpMenu(tester, head: true);

    final lo = lookupAppLocalizations(const Locale('lo'));
    expect(tester.takeException(), isNull);
    expect(find.text(lo.homeServicesTitle), findsOneWidget);
    // Seven, and the OT tile (#29).
    expect(find.text(lo.menuItemCount(8)), findsOneWidget);
    expect(find.text(lo.otMenu), findsOneWidget);
    expect(find.text(lo.salaryHistoryMenu), findsOneWidget);
    // The standalone "ອະນຸມັດແກ້ໄຂເວລາ" tile was folded into the combined
    // approvals page, so the menu carries that one instead: for heads and
    // HR only (#36).
    expect(find.text(lo.approvalsMenu), findsOneWidget);
    expect(find.text(lo.offsiteMenu), findsOneWidget);
  });
}
