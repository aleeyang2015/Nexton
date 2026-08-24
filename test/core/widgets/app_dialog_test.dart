import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/theme/app_colors.dart';
import 'package:next_on/core/widgets/app_dialog.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';

void main() {
  /// Wraps [child] with the delegates the dialog reads its default labels
  /// from.
  Widget app(Widget child) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: child,
  );

  /// Pumps a bare host and hands back a context under a Navigator.
  Future<BuildContext> host(WidgetTester tester) async {
    late BuildContext captured;

    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) {
            captured = context;
            return const Scaffold();
          },
        ),
      ),
    );

    return captured;
  }

  /// Pumps the dialog on its own, for inspecting how a variant renders.
  Future<void> pumpVariant(
    WidgetTester tester,
    AppDialogVariant variant,
  ) async {
    await tester.pumpWidget(
      app(
        Scaffold(
          body: AppDialog(variant: variant, message: 'x'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The filled call to action; the cancel affordance is a [TextButton].
  Color? confirmColour(WidgetTester tester) => tester
      .widget<ElevatedButton>(find.byType(ElevatedButton))
      .style
      ?.backgroundColor
      ?.resolve(<WidgetState>{});

  group('shape', () {
    testWidgets('shows the message and a default OK action', (tester) async {
      final context = await host(tester);

      unawaited(AppDialog.success(context, message: 'All done'));
      await tester.pumpAndSettle();

      expect(find.text('All done'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('renders a title above the message when given', (tester) async {
      final context = await host(tester);

      unawaited(
        AppDialog.error(context, title: 'Failed', message: 'Try again'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Failed'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('takes a custom confirm label', (tester) async {
      final context = await host(tester);

      unawaited(
        AppDialog.warning(context, message: 'Careful', confirmLabel: 'Got it'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Got it'), findsOneWidget);
      expect(find.text('OK'), findsNothing);
    });

    testWidgets('a long message wraps instead of being clipped', (
      tester,
    ) async {
      final context = await host(tester);
      const long =
          'Your account is not linked to an employee record. '
          'Please contact HR so they can finish setting you up.';

      unawaited(AppDialog.warning(context, message: long));
      await tester.pumpAndSettle();

      expect(tester.widget<Text>(find.text(long)).maxLines, greaterThan(1));
    });
  });

  group('variants', () {
    testWidgets('each carries its own icon and accent', (tester) async {
      const cases = <AppDialogVariant, (IconData, Color)>{
        AppDialogVariant.success: (Icons.check, AppColors.success),
        AppDialogVariant.warning: (Icons.priority_high, AppColors.warning),
        AppDialogVariant.error: (Icons.close, AppColors.danger),
        AppDialogVariant.question: (Icons.question_mark, AppColors.secondary),
      };

      for (final entry in cases.entries) {
        await pumpVariant(tester, entry.key);

        final (icon, accent) = entry.value;
        expect(find.byIcon(icon), findsOneWidget, reason: '${entry.key}');
        expect(
          tester.widget<Icon>(find.byIcon(icon)).color,
          accent,
          reason: '${entry.key}',
        );
      }
    });

    testWidgets('the action stays primary whatever the variant', (
      tester,
    ) async {
      for (final variant in AppDialogVariant.values) {
        await pumpVariant(tester, variant);

        // The accent belongs to the icon; the button never borrows it.
        expect(confirmColour(tester), AppColors.primary, reason: '$variant');
      }
    });

    testWidgets('only the question offers a way out', (tester) async {
      await pumpVariant(tester, AppDialogVariant.success);
      expect(find.byType(TextButton), findsNothing);

      await pumpVariant(tester, AppDialogVariant.question);
      expect(find.text('Cancel'), findsOneWidget);
    });
  });

  group('ask', () {
    testWidgets('confirming answers true', (tester) async {
      final context = await host(tester);

      final answer = AppDialog.ask(context, message: 'Delete this?');
      await tester.pumpAndSettle();

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(await answer, isTrue);
    });

    testWidgets('cancelling answers false', (tester) async {
      final context = await host(tester);

      final answer = AppDialog.ask(context, message: 'Delete this?');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(await answer, isFalse);
    });

    testWidgets('a dismissed question counts as no, never null', (
      tester,
    ) async {
      final context = await host(tester);

      final answer = AppDialog.ask(
        context,
        message: 'Delete this?',
        barrierDismissible: true,
      );
      await tester.pumpAndSettle();

      // Tap the barrier, well outside the dialog.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(await answer, isFalse);
    });
  });
}
