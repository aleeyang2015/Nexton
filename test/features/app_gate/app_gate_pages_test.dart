import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/features/app_gate/app_gate_providers.dart';
import 'package:next_on/features/app_gate/domain/app_gate_status.dart';
import 'package:next_on/features/app_gate/presentation/pages/maintenance_page.dart';
import 'package:next_on/features/app_gate/presentation/pages/update_required_page.dart';
import 'package:next_on/features/app_gate/presentation/providers/app_gate_notifier.dart';
import 'package:next_on/features/app_gate/presentation/providers/store_launcher_provider.dart';
import 'package:next_on/core/widgets/app_toast.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';
import 'package:next_on/l10n/generated/app_localizations_en.dart';

/// The two gate screens (#57).
void main() {
  final en = AppLocalizationsEn();

  Future<void> pump(
    WidgetTester tester,
    Widget page, {
    required AppGateStatus status,
    String platform = 'android',
    List<Uri>? opened,
    bool opens = true,
    _GateFake? gate,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appGateProvider.overrideWith(() => gate ?? _GateFake(status)),
          appPlatformProvider.overrideWithValue(platform),
          storeLauncherProvider.overrideWithValue((link) async {
            opened?.add(link);
            return opens;
          }),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          home: page,
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('update: Update opens the Play page on Android', (tester) async {
    final opened = <Uri>[];
    await pump(
      tester,
      const UpdateRequiredPage(),
      status: const AppGateUpdateRequired(),
      opened: opened,
    );
    expect(find.text(en.updateRequiredTitle), findsOneWidget);
    expect(find.text(en.updateRequiredBody), findsOneWidget);

    await tester.tap(find.text(en.updateRequiredButton));
    expect(opened, [Uri.parse(AppGateUpdateRequired.playStorePage)]);
  });

  testWidgets('update: the server\'s link wins', (tester) async {
    final opened = <Uri>[];
    await pump(
      tester,
      const UpdateRequiredPage(),
      status: const AppGateUpdateRequired('https://example.com/app'),
      opened: opened,
    );
    await tester.tap(find.text(en.updateRequiredButton));
    expect(opened, [Uri.parse('https://example.com/app')]);
  });

  testWidgets('the store does not open: said so, not a dead tap', (
    tester,
  ) async {
    await pump(
      tester,
      const UpdateRequiredPage(),
      status: const AppGateUpdateRequired(),
      opens: false,
    );
    await tester.tap(find.text(en.updateRequiredButton));
    await tester.pump();
    expect(find.text(en.genericError), findsOneWidget);
  });

  testWidgets('update on iOS with no link: the App Store line, no button', (
    tester,
  ) async {
    await pump(
      tester,
      const UpdateRequiredPage(),
      status: const AppGateUpdateRequired(),
      platform: 'ios',
    );
    expect(find.text(en.updateFromAppStore), findsOneWidget);
    expect(find.text(en.updateRequiredButton), findsNothing);
  });

  testWidgets('maintenance: the server\'s message, and Retry asks again', (
    tester,
  ) async {
    final gate = _GateFake(const AppGateMaintenance('Back at 10:00'));
    await pump(
      tester,
      const MaintenancePage(),
      status: const AppGateMaintenance('Back at 10:00'),
      gate: gate,
    );
    expect(find.text('Back at 10:00'), findsOneWidget);

    await tester.tap(find.text(en.retry));
    expect(gate.retries, 1);
  });

  testWidgets('maintenance with no message: the default words', (tester) async {
    await pump(
      tester,
      const MaintenancePage(),
      status: const AppGateMaintenance(),
    );
    expect(find.text(en.maintenanceDefaultBody), findsOneWidget);
  });

  testWidgets('no way back past either screen', (tester) async {
    await pump(
      tester,
      const UpdateRequiredPage(),
      status: const AppGateUpdateRequired(),
    );
    final scope = tester.widget<PopScope>(find.byType(PopScope));
    expect(scope.canPop, isFalse);
  });
}

class _GateFake extends AppGateNotifier {
  _GateFake(this.status);

  final AppGateStatus status;
  int retries = 0;

  @override
  AppGateStatus build() => status;

  @override
  Future<void> retry() async => retries++;
}
