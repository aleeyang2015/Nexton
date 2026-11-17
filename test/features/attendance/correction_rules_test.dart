import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/features/attendance/domain/entities/time_correction_request.dart';
import 'package:next_on/features/attendance/presentation/providers/time_correction_form_state.dart';
import 'package:next_on/core/errors/validation_codes.dart';
import 'package:next_on/features/attendance/domain/correction_rules.dart';
import 'package:next_on/features/attendance/domain/entities/time_correction_type.dart';
import 'package:next_on/features/profile/domain/entities/shift_detail.dart';
import 'package:next_on/features/profile/domain/entities/shift_detail_weekly.dart';

/// The "forgot to scan" rules the form checks first (#43).
void main() {
  Duration at(int h, [int m = 0]) => Duration(hours: h, minutes: m);

  // Friday 2026-11-13.
  final friday = DateTime(2026, 11, 13);

  const office = ShiftDetail(
    id: 'p1',
    startTime: '08:00',
    endTime: '17:00',
    earlyCheckinMinutes: 30,
    lateCheckoutMinutes: 60,
  );
  const night = ShiftDetail(
    id: 'p2',
    startTime: '22:00:00',
    endTime: '06:00:00',
    endsNextDay: true,
  );

  String? check(
    TimeCorrectionType type, {
    Duration? clockIn,
    Duration? clockOut,
    ShiftDetail? part = office,
  }) => CorrectionRules.check(
    type: type,
    clockIn: clockIn,
    clockOut: clockOut,
    part: part,
    date: friday,
  );

  group('look-back (decision 16: 30 days, no future)', () {
    final today = DateTime(2026, 11, 17, 9);
    final range = CorrectionRules.lookBack(today);

    test('today and 30 days back are in; 31 back and tomorrow are out', () {
      bool inRange(DateTime d) =>
          !d.isBefore(range.earliest) && !d.isAfter(range.latest);
      expect(inRange(DateTime(2026, 11, 17)), isTrue);
      expect(inRange(DateTime(2026, 10, 18)), isTrue);
      expect(inRange(DateTime(2026, 10, 17)), isFalse);
      expect(inRange(DateTime(2026, 11, 18)), isFalse);
    });
  });

  group('the part\'s window', () {
    test('08:00–17:00, 30 min early, 60 late: 07:30 and 18:00 in; 07:29 and '
        '18:01 out', () {
      expect(
        check(TimeCorrectionType.forgotClockIn, clockIn: at(7, 30)),
        isNull,
      );
      expect(
        check(TimeCorrectionType.forgotClockOut, clockOut: at(18)),
        isNull,
      );
      expect(
        check(TimeCorrectionType.forgotClockIn, clockIn: at(7, 29)),
        ValidationCode.correctionOutsideWindow,
      );
      expect(
        check(TimeCorrectionType.forgotClockOut, clockOut: at(18, 1)),
        ValidationCode.correctionOutsideWindow,
      );
    });

    test('overnight 22:00–06:00: 05:50 is the next morning, in; 06:01 out', () {
      expect(
        check(
          TimeCorrectionType.both,
          clockIn: at(22),
          clockOut: at(5, 50),
          part: night,
        ),
        isNull,
      );
      expect(
        check(
          TimeCorrectionType.forgotClockOut,
          clockOut: at(6, 1),
          part: night,
        ),
        ValidationCode.correctionOutsideWindow,
      );
    });

    test('a part whose end is not after its start is overnight even when '
        'ends_next_day is not sent', () {
      const unflagged = ShiftDetail(startTime: '22:00', endTime: '06:00');
      expect(CorrectionRules.window(unflagged, friday)!.overnight, isTrue);
    });

    test('the weekday\'s row wins over the part, times and minutes', () {
      const saturdayShort = ShiftDetail(
        startTime: '08:00',
        endTime: '17:00',
        lateCheckoutMinutes: 60,
        weeklys: [
          ShiftDetailWeekly(
            weeklyDay: 'FRI',
            endTime: '12:00',
            lateCheckoutMinutes: 0,
          ),
        ],
      );
      final window = CorrectionRules.window(saturdayShort, friday)!;
      expect(CorrectionRules.hhmm(window.to), '12:00');
      expect(
        check(
          TimeCorrectionType.forgotClockOut,
          clockOut: at(12, 1),
          part: saturdayShort,
        ),
        ValidationCode.correctionOutsideWindow,
      );
    });

    test(
      'a part with no times known: no window check (the server decides)',
      () {
        const unknown = ShiftDetail(id: 'p3');
        expect(CorrectionRules.window(unknown, friday), isNull);
        expect(
          check(
            TimeCorrectionType.forgotClockIn,
            clockIn: at(3),
            part: unknown,
          ),
          isNull,
        );
      },
    );
  });

  group('the times each type needs', () {
    test('forgot clock-in: the clock-in', () {
      expect(
        check(TimeCorrectionType.forgotClockIn),
        ValidationCode.correctionTimeRequired,
      );
    });

    test('forgot clock-out: the clock-out', () {
      expect(
        check(TimeCorrectionType.forgotClockOut),
        ValidationCode.correctionTimeRequired,
      );
    });

    test('both: both', () {
      expect(
        check(TimeCorrectionType.both, clockIn: at(8)),
        ValidationCode.correctionTimeRequired,
      );
    });

    test('wrong time: at least one is enough', () {
      expect(check(TimeCorrectionType.wrongTime, clockIn: at(8)), isNull);
      expect(check(TimeCorrectionType.wrongTime, clockOut: at(17)), isNull);
      expect(
        check(TimeCorrectionType.wrongTime),
        ValidationCode.correctionTimeRequired,
      );
    });

    test('a day part: the clock-out must come after the clock-in', () {
      expect(
        check(TimeCorrectionType.both, clockIn: at(16), clockOut: at(9)),
        ValidationCode.correctionInvalidTimes,
      );
    });
  });

  group('the form (#43)', () {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    test('a time outside the chosen part: shown at once under the times, the '
        'request is not sent, and the window is there for the text', () {
      final state = TimeCorrectionFormState(
        date: today,
        type: TimeCorrectionType.forgotClockIn,
        shiftDetail: office,
        clockIn: const TimeOfDay(hour: 7, minute: 0),
        reason: 'Forgot',
      );

      expect(
        state.errorFor(TimeCorrectionFields.times),
        ValidationCode.correctionOutsideWindow,
      );
      expect(state.toRequest().validate().isFailure, isTrue);
      expect(CorrectionRules.hhmm(state.window!.from), '07:30');
      expect(CorrectionRules.hhmm(state.window!.to), '18:00');
    });

    test('the part goes with the request (not on the wire)', () {
      final state = TimeCorrectionFormState(date: today, shiftDetail: office);
      expect(state.toRequest().part, office);
    });
  });
}
