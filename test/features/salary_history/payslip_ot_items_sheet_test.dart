import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/features/salary_history/domain/entities/payslip_record.dart';
import 'package:next_on/features/salary_history/presentation/widgets/payslip_ot_items_sheet.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';
import 'package:next_on/l10n/generated/app_localizations_en.dart';
import 'package:next_on/l10n/generated/app_localizations_lo.dart';

import '../../support/salary_test_doubles.dart';

/// The sheet that opens from a payslip's OT line: each OT piece the line
/// paid, as the server sends it.
void main() {
  final en = AppLocalizationsEn();
  final lo = AppLocalizationsLo();

  Future<void> pumpSheet(
    WidgetTester tester, {
    List<PayslipOvertimeItem>? items,
    int total = 162259,
    String locale = 'en',
  }) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        locale: Locale(locale),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: PayslipOtItemsSheet(
            items: items ?? samplePayslipOvertimeItems,
            total: total,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The texts inside the row for [pieceId].
  List<String> rowTexts(WidgetTester tester, String pieceId) => [
    for (final element
        in find
            .descendant(
              of: find.byKey(ValueKey('ot-piece-$pieceId')),
              matching: find.byType(Text),
            )
            .evaluate())
      (element.widget as Text).data ?? '',
  ];

  testWidgets('has the title', (tester) async {
    await pumpSheet(tester);

    expect(find.text(en.payslipOtDetailsTitle), findsOneWidget);
  });

  testWidgets('one row per piece, in the server\'s order, each with date, '
      'window, pay, paid time and amount', (tester) async {
    await pumpSheet(tester);

    expect(rowTexts(tester, 'piece-1'), [
      '28/09/2026',
      '18:00–20:00',
      '43,269',
      '150%',
      '2 h 0 min',
    ]);
    expect(rowTexts(tester, 'piece-2'), [
      '03/10/2026',
      '17:00–18:30',
      '30,000',
      '20,000 kip/h',
      '1 h 30 min',
    ]);

    final tops = [
      for (final id in ['piece-1', 'piece-2', 'piece-3'])
        tester.getTopLeft(find.byKey(ValueKey('ot-piece-$id'))).dy,
    ];
    expect(tops, orderedEquals([...tops]..sort()));
  });

  testWidgets('a piece dated in the month before the payslip shows its own '
      'date', (tester) async {
    await pumpSheet(tester);

    expect(rowTexts(tester, 'piece-1').first, '28/09/2026');
  });

  testWidgets('a piece that paid nothing shows 0 min and 0, with the note, '
      'and is not hidden', (tester) async {
    await pumpSheet(tester);

    final texts = rowTexts(tester, 'piece-3');
    expect(texts, contains('07:00–08:00'));
    expect(texts, contains('0 min'));
    expect(texts, contains('0'));
    expect(texts, contains(en.payslipOtNotPaidNote));
    // Only that row carries the note.
    expect(find.text(en.payslipOtNotPaidNote), findsOneWidget);
  });

  testWidgets('in Lao: 0 ນາທີ, 2 ຊມ 0 ນາທີ, ກີບ/ຊມ and the Lao note', (
    tester,
  ) async {
    await pumpSheet(tester, locale: 'lo');

    expect(find.text(lo.payslipOtDetailsTitle), findsOneWidget);
    expect(rowTexts(tester, 'piece-1'), contains('2 ຊມ 0 ນາທີ'));
    expect(rowTexts(tester, 'piece-2'), contains('20,000 ກີບ/ຊມ'));
    expect(rowTexts(tester, 'piece-3'), contains('0 ນາທີ'));
    expect(find.text(lo.payslipOtNotPaidNote), findsOneWidget);
  });

  testWidgets('the total is the OT line\'s own amount, not the pieces added '
      'up', (tester) async {
    await pumpSheet(tester);

    expect(find.text(en.payslipOtTotal), findsOneWidget);
    expect(find.text('162,259'), findsOneWidget);
    // 43,269 + 30,000 + 0
    expect(find.text('73,269'), findsNothing);
  });

  testWidgets('a piece with no times or date shows what it has, without a '
      'stray dash', (tester) async {
    await pumpSheet(
      tester,
      items: const [
        PayslipOvertimeItem(
          pieceId: 'bare',
          payType: PayslipOvertimePayType.unknown,
          payValue: 175,
          paidMinutes: 45,
          amount: 12000,
        ),
      ],
      total: 12000,
    );

    expect(rowTexts(tester, 'bare'), ['12,000', '175', '45 min']);
  });

  testWidgets('a long list scrolls inside the sheet without overflowing', (
    tester,
  ) async {
    final many = [
      for (var i = 0; i < 40; i++)
        PayslipOvertimeItem(
          pieceId: 'p$i',
          workDate: DateTime(2026, 10, 1 + i % 28),
          startsAt: DateTime(2026, 10, 1 + i % 28, 18),
          endsAt: DateTime(2026, 10, 1 + i % 28, 19),
          payType: PayslipOvertimePayType.percent,
          payValue: 150,
          paidMinutes: 60,
          amount: 21634,
        ),
    ];
    tester.view.physicalSize = const Size(900, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () =>
                    showPayslipOtItemsSheet(context, items: many, total: 1),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(en.payslipOtDetailsTitle), findsOneWidget);
    // The total stays in view under the scrolling list.
    expect(find.text(en.payslipOtTotal), findsOneWidget);
  });
}
