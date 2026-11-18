import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/constants/app_constants.dart';
import 'package:next_on/core/network/network_providers.dart';
import 'package:next_on/features/auth/auth_providers.dart';
import 'package:next_on/features/auth/presentation/pages/login_page.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';
import 'package:next_on/l10n/generated/app_localizations_en.dart';
import 'package:next_on/l10n/generated/app_localizations_lo.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/auth_test_doubles.dart';
import '../../support/test_asset_bundle.dart';

/// The login screen's two controls that did nothing (#60).
void main() {
  late FakeAuthRepository auth;

  setUp(() => auth = FakeAuthRepository());
  tearDown(() => auth.sessionExpired.close());

  Future<void> pumpLogin(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    Map<String, Object> saved = const {},
  }) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues(saved);
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: DefaultAssetBundle(
          bundle: TestAssetBundle(),
          child: MaterialApp(
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const LoginPage(),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  for (final (language, l10n) in <(String, AppLocalizations)>[
    ('en', AppLocalizationsEn()),
    ('lo', AppLocalizationsLo()),
  ]) {
    testWidgets('"Forgot password?" says to ask HR ($language)', (
      tester,
    ) async {
      await pumpLogin(tester, locale: Locale(language));

      await tester.tap(find.text(l10n.forgotPassword));
      await tester.pumpAndSettle();

      expect(find.text(l10n.forgotPasswordAskHr), findsOneWidget);
    });
  }

  testWidgets('"Forgot password?" is a big enough target (44 × 44)', (
    tester,
  ) async {
    await pumpLogin(tester);
    final en = AppLocalizationsEn();
    final target = find.ancestor(
      of: find.text(en.forgotPassword),
      matching: find.byType(InkWell),
    );
    final size = tester.getSize(target.first);
    expect(size.width, greaterThanOrEqualTo(44));
    expect(size.height, greaterThanOrEqualTo(44));
  });

  testWidgets('a remembered email fills the field once; typing is kept', (
    tester,
  ) async {
    await pumpLogin(
      tester,
      saved: {AppConstants.rememberedEmailKey: 'noy.s@shop.la'},
    );
    final email = find.byType(TextField).first;
    expect(tester.widget<TextField>(email).controller!.text, 'noy.s@shop.la');

    await tester.enterText(email, 'bee@shop.la');
    await tester.pump();
    // A rebuild does not put the saved email back.
    await tester.tap(find.byType(TextField).last);
    await tester.pump();
    expect(tester.widget<TextField>(email).controller!.text, 'bee@shop.la');
  });

  testWidgets('nothing remembered: the field is empty', (tester) async {
    await pumpLogin(tester);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      isEmpty,
    );
  });
}
