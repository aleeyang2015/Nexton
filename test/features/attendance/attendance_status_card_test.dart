import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/utils/clock_provider.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/attendance/attendance_providers.dart';
import 'package:next_on/features/attendance/domain/entities/attendance_day.dart';
import 'package:next_on/features/attendance/presentation/widgets/attendance_status_card.dart';
import 'package:next_on/features/attendance/presentation/widgets/shift_session_slot.dart';
import 'package:next_on/features/profile/domain/entities/employee_profile.dart';
import 'package:next_on/features/profile/domain/entities/shift_detail.dart';
import 'package:next_on/features/profile/domain/entities/shift_detail_weekly.dart';
import 'package:next_on/features/profile/presentation/providers/profile_notifier.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';

import '../../support/attendance_test_doubles.dart';
import '../../support/test_asset_bundle.dart';

const _morning = ShiftDetail(
  name: 'Morning',
  nameLo: 'ກະເຊົ້າ',
  startTime: '08:00:00',
  endTime: '12:00:00',
);
const _afternoon = ShiftDetail(
  name: 'Afternoon',
  nameLo: 'ກະແລງ',
  startTime: '13:00:00',
  endTime: '17:00:00',
);

DateTime _todayAt(int hour, int minute) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day, hour, minute);
}

class _FixedProfileNotifier extends ProfileNotifier {
  final EmployeeProfile profile;

  _FixedProfileNotifier(this.profile);

  @override
  Future<EmployeeProfile> build() async => profile;
}

void main() {
  group('ShiftSessionSlot.build', () {
    test('pairs each segment with the session whose label starts with it', () {
      final afternoon = AttendanceSession(
        label: '13:00–17:00',
        clockIn: _todayAt(12, 58),
      );

      final slots = ShiftSessionSlot.build([_morning, _afternoon], [afternoon]);

      // An afternoon-only day leaves the morning tile empty.
      expect(slots[0].session, isNull);
      expect(slots[1].session, afternoon);
      expect(slots[1].isAwaitingClockOut, isTrue);
    });

    test('places an unlabelled 12:00 clock-in in the afternoon, not the '
        'morning', () {
      final noon = AttendanceSession(clockIn: _todayAt(12, 0));

      final slots = ShiftSessionSlot.build([_morning, _afternoon], [noon]);

      expect(slots[0].session, isNull);
      expect(slots[1].session, noon);
    });

    test('places an unlabelled clock-in inside a window in that segment', () {
      final late = AttendanceSession(clockIn: _todayAt(10, 30));
      final afterHours = AttendanceSession(clockIn: _todayAt(18, 0));

      expect(
        ShiftSessionSlot.build([_morning, _afternoon], [late])[0].session,
        late,
      );
      expect(
        ShiftSessionSlot.build([_morning, _afternoon], [afterHours])[1].session,
        afterHours,
      );
    });

    test('reads a single-digit hour in the label', () {
      final morning = AttendanceSession(
        label: '8:00-12:00',
        clockIn: _todayAt(12, 0),
      );

      final slots = ShiftSessionSlot.build([_morning, _afternoon], [morning]);

      // The backend's own label wins over the clock-in time.
      expect(slots[0].session, morning);
    });

    test('uses the clock-in time for a session with no label', () {
      final morning = AttendanceSession(
        clockIn: _todayAt(8, 2),
        clockOut: _todayAt(12, 5),
      );

      final slots = ShiftSessionSlot.build([_morning, _afternoon], [morning]);

      expect(slots[0].session, morning);
      expect(slots[0].isAwaitingClockOut, isFalse);
      expect(slots[1].session, isNull);
    });
  });

  group('ShiftSessionSlot.build on a weekday with its own times', () {
    final saturday = DateTime(2026, 11, 14);
    AttendanceSession at(int hour, int minute, {String? part, String? label}) =>
        AttendanceSession(
          clockIn: DateTime(2026, 11, 14, hour, minute),
          partStartTime: part,
          label: label,
        );

    test('a split day keeps each punch on its own tile', () {
      final slots = ShiftSessionSlot.build(
        [_morning, _afternoon],
        [at(8, 2), at(13, 5)],
        day: saturday,
      );

      expect(slots[0].clockIn!.hour, 8);
      expect(slots[1].clockIn!.hour, 13);
    });

    test('a row that moves the windows moves where a punch lands', () {
      // Saturday: 10:00–13:00 and 14:00–18:00 instead of 08–12 / 13–17.
      const morning = ShiftDetail(
        startTime: '08:00',
        endTime: '12:00',
        weeklys: [
          ShiftDetailWeekly(weeklyDay: 'SAT', startTime: '10:00', endTime: '13:00'),
        ],
      );
      const afternoon = ShiftDetail(
        startTime: '13:00',
        endTime: '17:00',
        weeklys: [
          ShiftDetailWeekly(weeklyDay: 'SAT', startTime: '14:00', endTime: '18:00'),
        ],
      );

      // 12:30 is the afternoon on a weekday, still the morning on Saturday.
      final onSaturday = ShiftSessionSlot.build(
        [morning, afternoon],
        [at(12, 30)],
        day: saturday,
      );
      final onUsualHours = ShiftSessionSlot.build([morning, afternoon], [
        at(12, 30),
      ]);

      expect(onSaturday[0].session, isNotNull);
      expect(onSaturday[1].session, isNull);
      expect(onUsualHours[1].session, isNotNull);
    });

    test('a row with only one time does not lose a punch', () {
      const morning = ShiftDetail(
        startTime: '08:00',
        endTime: '12:00',
        weeklys: [ShiftDetailWeekly(weeklyDay: 'SAT', startTime: '08:30')],
      );

      final slots = ShiftSessionSlot.build(
        [morning, _afternoon],
        [at(8, 32), at(13, 5)],
        day: saturday,
      );

      expect(slots[0].clockIn!.hour, 8);
      expect(slots[1].clockIn!.hour, 13);
    });

    test('when a row makes two windows overlap, the part the backend filed '
        'the punch under decides', () {
      // Saturday's morning runs to 14:00, over the afternoon's 13:00 start.
      const morning = ShiftDetail(
        startTime: '08:00',
        endTime: '12:00',
        weeklys: [ShiftDetailWeekly(weeklyDay: 'SAT', endTime: '14:00')],
      );

      final byPart = ShiftSessionSlot.build(
        [morning, _afternoon],
        [at(13, 5, part: '13:00:00')],
        day: saturday,
      );
      final byLabel = ShiftSessionSlot.build(
        [morning, _afternoon],
        [at(13, 5, label: '13:00–17:00')],
        day: saturday,
      );

      expect(byPart[1].session, isNotNull);
      expect(byPart[0].session, isNull);
      expect(byLabel[1].session, isNotNull);
    });

    test('a part time the backend sent as the usual start still finds its '
        'tile when the weekday row moved that start', () {
      const afternoon = ShiftDetail(
        startTime: '13:00',
        endTime: '17:00',
        weeklys: [
          ShiftDetailWeekly(weeklyDay: 'SAT', startTime: '14:00', endTime: '18:00'),
        ],
      );

      final slots = ShiftSessionSlot.build(
        [_morning, afternoon],
        [at(13, 40, part: '13:00:00')],
        day: saturday,
      );

      expect(slots[1].session, isNotNull);
    });
  });

  group('AttendanceStatusCard', () {
    late FakeAttendanceRepository repository;

    setUp(() {
      repository = FakeAttendanceRepository()
        ..today = Result.success(
          AttendanceDay(
            sessions: [
              AttendanceSession(
                label: '08:00–12:00',
                clockIn: _todayAt(8, 2),
                clockOut: _todayAt(12, 5),
              ),
              AttendanceSession(
                label: '13:00–17:00',
                clockIn: _todayAt(12, 58),
              ),
            ],
          ),
        );
    });

    Future<void> pumpCard(
      WidgetTester tester, {
      List<ShiftDetail> shiftDetails = const [_morning, _afternoon],
      DateTime Function()? now,
    }) async {
      // A small phone, in Lao — the tightest case for the card's text.
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            attendanceRepositoryProvider.overrideWithValue(repository),
            if (now != null) clockProvider.overrideWithValue(now),
            profileNotifierProvider.overrideWith(
              () => _FixedProfileNotifier(
                EmployeeProfile(
                  id: '1',
                  fullName: 'Test',
                  shiftDetails: shiftDetails,
                ),
              ),
            ),
          ],
          child: DefaultAssetBundle(
            bundle: TestAssetBundle(),
            child: MaterialApp(
              locale: const Locale('lo'),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: const Scaffold(
                body: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: AttendanceStatusCard(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }

    testWidgets('shows each segment\'s punches from today\'s record', (
      tester,
    ) async {
      final lo = lookupAppLocalizations(const Locale('lo'));

      await pumpCard(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('ກະເຊົ້າ'), findsOneWidget);
      expect(find.text('ກະແລງ'), findsOneWidget);
      expect(find.text('08:02'), findsOneWidget);
      expect(find.text('12:05'), findsOneWidget);
      expect(find.text('12:58'), findsOneWidget);
      // The open afternoon session is still owed a clock-out.
      expect(
        find.textContaining(lo.sessionAwaitingClockOut, findRichText: true),
        findsOneWidget,
      );
      expect(find.text(lo.slideToClockOut), findsOneWidget);
    });

    testWidgets('the methods row says GPS only', (tester) async {
      final lo = lookupAppLocalizations(const Locale('lo'));

      await pumpCard(tester);

      expect(AttendanceStatusCard.methods, ['gps']);
      expect(find.textContaining(lo.methodGps), findsOneWidget);
      expect(find.textContaining(lo.methodWifi), findsNothing);
      expect(find.textContaining(lo.methodBiometric), findsNothing);
      expect(find.textContaining(lo.methodField), findsNothing);
    });

    group('a weekday with its own times', () {
      // The shop works 08:00–17:00 but closes at noon on Saturday.
      const shop = ShiftDetail(
        name: 'Day',
        nameLo: 'ກະກາງເວັນ',
        startTime: '08:00:00',
        endTime: '17:00:00',
        weeklys: [
          ShiftDetailWeekly(
            weeklyDay: 'SAT',
            startTime: '08:00:00',
            endTime: '12:00:00',
          ),
        ],
      );

      testWidgets('on Saturday the tile shows 08:00-12:00', (tester) async {
        repository.today = const Result.success(AttendanceDay.empty);

        await pumpCard(
          tester,
          shiftDetails: const [shop],
          now: () => DateTime(2026, 11, 14, 9),
        );

        expect(find.text('08:00-12:00'), findsOneWidget);
        expect(find.text('08:00-17:00'), findsNothing);
      });

      testWidgets('on a weekday the tile shows the part\'s own times', (
        tester,
      ) async {
        repository.today = const Result.success(AttendanceDay.empty);

        await pumpCard(
          tester,
          shiftDetails: const [shop],
          now: () => DateTime(2026, 11, 13, 9),
        );

        expect(find.text('08:00-17:00'), findsOneWidget);
        expect(find.text('08:00-12:00'), findsNothing);
      });

      testWidgets('the record\'s date decides, not today: Saturday\'s record '
          'still open on Sunday shows Saturday\'s hours', (tester) async {
        repository.today = Result.success(
          AttendanceDay(
            date: DateTime(2026, 11, 14),
            sessions: [
              AttendanceSession(clockIn: DateTime(2026, 11, 14, 8, 1)),
            ],
          ),
        );

        await pumpCard(
          tester,
          shiftDetails: const [shop],
          now: () => DateTime(2026, 11, 15, 1),
        );

        expect(find.text('08:00-12:00'), findsOneWidget);
      });
    });

    testWidgets('hides the shift line and grid when there is no shift', (
      tester,
    ) async {
      await pumpCard(tester, shiftDetails: const []);

      expect(tester.takeException(), isNull);
      expect(find.text('08:02'), findsNothing);
      expect(
        find.textContaining('08:00 - 12:00', findRichText: true),
        findsNothing,
      );
    });
  });
}
