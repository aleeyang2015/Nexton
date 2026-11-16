import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/features/time_off/domain/entities/company_days_off.dart';
import 'package:next_on/features/time_off/presentation/providers/leave_request_form_state.dart';
import 'package:next_on/features/time_off/presentation/widgets/leave_dates_calendar_dialog.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';
import 'package:next_on/l10n/generated/app_localizations_en.dart';

void main() {
  final en = AppLocalizationsEn();

  // The dialog opens on the month of today (or of its first picked day), so
  // the days used here are taken from the current month: its first Sunday,
  // and the Friday, Saturday and Monday around it.
  final today = DateUtils.dateOnly(DateTime.now());
  final firstOfMonth = DateTime(today.year, today.month);
  // The second Sunday of the month: never earlier than the 8th, so the
  // Friday before it is in the same month, and the Monday after it too.
  final sunday = DateTime(
    today.year,
    today.month,
    1 + (DateTime.sunday - firstOfMonth.weekday) % 7 + 7,
  );
  final friday = DateTime(sunday.year, sunday.month, sunday.day - 2);
  final saturday = DateTime(sunday.year, sunday.month, sunday.day - 1);
  final monday = DateTime(sunday.year, sunday.month, sunday.day + 1);

  const sundaysOff = CompanyDaysOff([
    RestDayRule(type: RestDayType.weekly, value: 'SUN'),
  ]);

  LeaveCalendarResult? result;
  var closed = false;

  Future<void> open(
    WidgetTester tester, {
    required LeaveDaysMode mode,
    CompanyDaysOff? daysOff = sundaysOff,
    List<DateTime> initialDates = const [],
    DateTime? rangeStart,
    DateTime? rangeEnd,
    bool halfDay = false,
  }) async {
    result = null;
    closed = false;
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await LeaveDatesCalendarDialog.show(
                context,
                mode: mode,
                initialDates: initialDates,
                initialRangeStart: rangeStart,
                initialRangeEnd: rangeEnd,
                halfDay: halfDay,
                daysOff: daysOff,
              );
              closed = true;
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> tapDay(WidgetTester tester, DateTime day) async {
    await tester.tap(find.text('${day.day}'));
    await tester.pump();
  }

  Future<void> confirm(WidgetTester tester) async {
    await tester.tap(find.text(en.leaveSelectButtonLabel));
    await tester.pumpAndSettle();
    expect(closed, isTrue);
  }

  Text dayText(WidgetTester tester, DateTime day) =>
      tester.widget<Text>(find.text('${day.day}'));

  group('separate days', () {
    testWidgets('a company day off cannot be tapped', (tester) async {
      await open(tester, mode: LeaveDaysMode.separateDays);

      await tapDay(tester, sunday);
      await tapDay(tester, monday);
      await confirm(tester);

      expect(result!.dates, [monday]);
      expect(result!.rangeStart, isNull);
    });

    testWidgets('a day off is struck through; a working day is not', (
      tester,
    ) async {
      await open(tester, mode: LeaveDaysMode.separateDays);

      expect(
        dayText(tester, sunday).style!.decoration,
        TextDecoration.lineThrough,
      );
      expect(dayText(tester, monday).style!.decoration, isNull);
      expect(find.text(en.leaveDayOffLegend), findsOneWidget);
    });

    testWidgets('a day picked before it became a day off stays shown with '
        'the mark, and can be removed but not put back', (tester) async {
      await open(
        tester,
        mode: LeaveDaysMode.separateDays,
        initialDates: [saturday, sunday],
      );

      expect(
        dayText(tester, sunday).style!.decoration,
        TextDecoration.lineThrough,
      );
      expect(find.text('2 days'), findsOneWidget);

      await tapDay(tester, sunday);
      expect(find.text('1 days'), findsOneWidget);

      await tapDay(tester, sunday);
      expect(find.text('1 days'), findsOneWidget);

      await confirm(tester);
      expect(result!.dates, [saturday]);
    });

    testWidgets('with the days off unknown every day can be picked, and '
        'there is no legend', (tester) async {
      await open(tester, mode: LeaveDaysMode.separateDays, daysOff: null);

      await tapDay(tester, sunday);
      await confirm(tester);

      expect(result!.dates, [sunday]);
      expect(find.text(en.leaveDayOffLegend), findsNothing);
    });

    testWidgets('a half day keeps one date', (tester) async {
      await open(tester, mode: LeaveDaysMode.separateDays, halfDay: true);

      await tapDay(tester, friday);
      await tapDay(tester, monday);
      await confirm(tester);

      expect(result!.dates, [monday]);
    });
  });

  group('a date range', () {
    testWidgets('the first tap is the first day, the second the last, and '
        'the footer counts the days that are not days off', (tester) async {
      await open(tester, mode: LeaveDaysMode.range);
      expect(find.text(en.leavePickRangeStart), findsOneWidget);

      await tapDay(tester, friday);
      expect(find.text(en.leavePickRangeEnd), findsOneWidget);
      expect(find.text('1 days'), findsOneWidget);

      await tapDay(tester, monday);
      // Friday, Saturday, Monday: the Sunday in between is not counted.
      expect(find.text('3 days'), findsOneWidget);

      await confirm(tester);
      expect(result!.rangeStart, friday);
      expect(result!.rangeEnd, monday);
      expect(result!.dates, isEmpty);
    });

    testWidgets('a second tap before the first puts the two in order', (
      tester,
    ) async {
      await open(tester, mode: LeaveDaysMode.range);

      await tapDay(tester, monday);
      await tapDay(tester, friday);
      await confirm(tester);

      expect(result!.rangeStart, friday);
      expect(result!.rangeEnd, monday);
    });

    testWidgets('a third tap starts again', (tester) async {
      await open(tester, mode: LeaveDaysMode.range);

      await tapDay(tester, friday);
      await tapDay(tester, monday);
      await tapDay(tester, saturday);
      await confirm(tester);

      expect(result!.rangeStart, saturday);
      expect(result!.rangeEnd, saturday);
    });

    testWidgets('a day off inside the range stays grey and struck through', (
      tester,
    ) async {
      await open(
        tester,
        mode: LeaveDaysMode.range,
        rangeStart: friday,
        rangeEnd: monday,
      );

      expect(
        dayText(tester, sunday).style!.decoration,
        TextDecoration.lineThrough,
      );
      expect(dayText(tester, saturday).style!.color, Colors.white);
      expect(dayText(tester, sunday).style!.color, isNot(Colors.white));
      expect(find.text('3 days'), findsOneWidget);
    });

    testWidgets('a range may end on a day off; the count leaves it out', (
      tester,
    ) async {
      await open(tester, mode: LeaveDaysMode.range);

      await tapDay(tester, saturday);
      await tapDay(tester, sunday);

      expect(find.text('1 days'), findsOneWidget);
    });

    testWidgets('with the days off unknown the footer leaves the count to '
        'the server', (tester) async {
      await open(tester, mode: LeaveDaysMode.range, daysOff: null);

      await tapDay(tester, friday);
      await tapDay(tester, monday);

      expect(find.text(en.leaveRangeCountByServer), findsOneWidget);
      expect(find.text(en.leaveDatesTotalPrefix), findsNothing);
    });

    testWidgets('closing without choosing returns nothing', (tester) async {
      await open(tester, mode: LeaveDaysMode.range);

      await tapDay(tester, friday);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(closed, isTrue);
      expect(result, isNull);
    });
  });
}
