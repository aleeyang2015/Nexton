import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/widgets/load_more_footer.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';

void main() {
  var retries = 0;

  Future<void> pump(
    WidgetTester tester, {
    required bool loadingMore,
    required bool failed,
    String locale = 'en',
  }) async {
    retries = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: Locale(locale),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: LoadMoreFooter(
            loadingMore: loadingMore,
            failed: failed,
            onRetry: () => retries++,
          ),
        ),
      ),
    );
  }

  testWidgets('a spinner while the next page is on its way', (tester) async {
    await pump(tester, loadingMore: true, failed: false);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Could not load more.'), findsNothing);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('"could not load more" and Retry when it failed', (tester) async {
    await pump(tester, loadingMore: false, failed: true);

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Could not load more.'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    expect(retries, 1);
  });

  testWidgets('nothing otherwise', (tester) async {
    await pump(tester, loadingMore: false, failed: false);

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(Text), findsNothing);
    expect(tester.getSize(find.byType(LoadMoreFooter)).height, 0);
  });

  testWidgets('a retry under way shows the spinner, not the error', (
    tester,
  ) async {
    await pump(tester, loadingMore: true, failed: true);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Could not load more.'), findsNothing);
  });

  testWidgets('in Lao', (tester) async {
    await pump(tester, loadingMore: false, failed: true, locale: 'lo');

    expect(find.text('ໂຫຼດເພີ່ມບໍ່ໄດ້.'), findsOneWidget);
    expect(find.text('ລອງໃໝ່'), findsOneWidget);
  });
}
