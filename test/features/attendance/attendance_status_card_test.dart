import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/attendance/attendance_providers.dart';
import 'package:next_on/features/attendance/domain/entities/attendance_day.dart';
import 'package:next_on/features/attendance/presentation/widgets/attendance_status_card.dart';
import 'package:next_on/features/attendance/presentation/widgets/shift_session_slot.dart';
import 'package:next_on/features/profile/domain/entities/employee_profile.dart';
import 'package:next_on/features/profile/domain/entities/shift_detail.dart';
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
    }) async {
      // A small phone, in Lao — the tightest case for the card's text.
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            attendanceRepositoryProvider.overrideWithValue(repository),
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
