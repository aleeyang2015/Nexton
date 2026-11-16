import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/features/attendance/domain/entities/attendance_day.dart';

void main() {
  /// Tuesday 17 November 2026, 09:00 unless a case says otherwise.
  final now = DateTime(2026, 11, 17, 9);
  final yesterday = DateTime(2026, 11, 16);
  final today = DateTime(2026, 11, 17);
  final tomorrow = DateTime(2026, 11, 18);

  AttendanceSession session({
    required DateTime clockIn,
    DateTime? clockOut,
    String? start,
    String? end,
  }) => AttendanceSession(
    clockIn: clockIn,
    clockOut: clockOut,
    partStartTime: start,
    partEndTime: end,
  );

  /// A record on [date] with one session open since [clockIn].
  AttendanceDay open(
    DateTime date,
    DateTime clockIn, {
    String? start,
    String? end,
  }) => AttendanceDay(
    date: date,
    sessions: [session(clockIn: clockIn, start: start, end: end)],
  );

  /// A record on [date] with one finished session.
  AttendanceDay closed(DateTime date) => AttendanceDay(
    date: date,
    sessions: [
      session(
        clockIn: date.add(const Duration(hours: 8)),
        clockOut: date.add(const Duration(hours: 17)),
        start: '08:00',
        end: '17:00',
      ),
    ],
  );

  group('pickCurrent, in order', () {
    test('1. tomorrow\'s record with an open session wins over everything', () {
      final ahead = open(
        tomorrow,
        DateTime(2026, 11, 17, 23, 50),
        start: '00:00',
        end: '08:00',
      );
      final rows = [
        ahead,
        open(today, DateTime(2026, 11, 17, 8), start: '08:00', end: '17:00'),
        open(
          yesterday,
          DateTime(2026, 11, 16, 23, 35),
          start: '23:30',
          end: '07:30',
        ),
      ];

      expect(
        AttendanceDay.pickCurrent(rows, DateTime(2026, 11, 17, 23, 55)),
        same(ahead),
      );
    });

    test('2. today\'s record with an open session', () {
      final current = open(
        today,
        DateTime(2026, 11, 17, 8),
        start: '08:00',
        end: '17:00',
      );
      final rows = [
        closed(tomorrow),
        current,
        open(
          yesterday,
          DateTime(2026, 11, 16, 23, 35),
          start: '23:30',
          end: '07:30',
        ),
      ];

      expect(AttendanceDay.pickCurrent(rows, now), same(current));
    });

    test('3. yesterday\'s open session whose part crosses midnight', () {
      final night = open(
        yesterday,
        DateTime(2026, 11, 16, 23, 35),
        start: '23:30',
        end: '07:30',
      );
      final rows = [closed(today), night];

      expect(AttendanceDay.pickCurrent(rows, now), same(night));
    });

    test('4. today\'s record, when nothing is open', () {
      final current = closed(today);
      final rows = [closed(tomorrow), current, closed(yesterday)];

      expect(AttendanceDay.pickCurrent(rows, now), same(current));
    });

    test('5. empty, when today has no record', () {
      expect(
        AttendanceDay.pickCurrent([closed(yesterday)], now),
        AttendanceDay.empty,
      );
      expect(AttendanceDay.pickCurrent(const [], now), AttendanceDay.empty);
    });
  });

  group('the cases the order is for', () {
    test('a day shift left open yesterday is not picked: the card offers '
        'clock-in', () {
      // Lae forgot to clock out on Monday.
      final rows = [
        open(
          yesterday,
          DateTime(2026, 11, 16, 8),
          start: '08:00',
          end: '17:00',
        ),
      ];

      final picked = AttendanceDay.pickCurrent(rows, now);

      expect(picked, AttendanceDay.empty);
      expect(picked.nextAction, ClockAction.clockIn);
    });

    test('a 23:30–07:30 part opened yesterday at 23:35 is picked at 02:00', () {
      final night = open(
        yesterday,
        DateTime(2026, 11, 16, 23, 35),
        start: '23:30',
        end: '07:30',
      );

      final picked = AttendanceDay.pickCurrent([
        night,
      ], DateTime(2026, 11, 17, 2));

      expect(picked, same(night));
      expect(picked.nextAction, ClockAction.clockOut);
    });

    test('a 00:00 shift opened at 23:50 on tomorrow\'s record is picked', () {
      final ahead = open(
        tomorrow,
        DateTime(2026, 11, 17, 23, 50),
        start: '00:00',
        end: '08:00',
      );

      final picked = AttendanceDay.pickCurrent([
        ahead,
      ], DateTime(2026, 11, 17, 23, 55));

      expect(picked, same(ahead));
      expect(picked.nextAction, ClockAction.clockOut);
    });

    test('yesterday\'s open session with no shift part is not picked', () {
      // Without the part's times it cannot be called a night shift.
      final rows = [open(yesterday, DateTime(2026, 11, 16, 23, 35))];

      expect(AttendanceDay.pickCurrent(rows, now), AttendanceDay.empty);
    });

    test('a record two days old is never picked, night shift or not', () {
      final rows = [
        open(
          DateTime(2026, 11, 15),
          DateTime(2026, 11, 15, 23, 35),
          start: '23:30',
          end: '07:30',
        ),
      ];

      expect(AttendanceDay.pickCurrent(rows, now), AttendanceDay.empty);
    });

    test('a record with no date is ignored', () {
      final rows = [
        AttendanceDay(
          sessions: [session(clockIn: DateTime(2026, 11, 17, 8))],
        ),
      ];

      expect(AttendanceDay.pickCurrent(rows, now), AttendanceDay.empty);
    });

    test('the days are calendar days: across a month and a year end', () {
      final night = open(
        DateTime(2026, 12, 31),
        DateTime(2026, 12, 31, 23, 35),
        start: '23:30',
        end: '07:30',
      );

      expect(
        AttendanceDay.pickCurrent([night], DateTime(2027, 1, 1, 2)),
        same(night),
      );
    });
  });

  group('openSession', () {
    test('with two sessions open, it is the one opened last', () {
      // Yesterday: a forgotten clock-out on the day part, and the night part
      // still running. The record is picked for the night part, and that is
      // the session the card must name.
      final day = AttendanceDay(
        date: yesterday,
        sessions: [
          AttendanceSession(
            label: '08:00–17:00',
            clockIn: DateTime(2026, 11, 16, 8),
            partStartTime: '08:00',
            partEndTime: '17:00',
          ),
          AttendanceSession(
            label: '23:30–07:30',
            clockIn: DateTime(2026, 11, 16, 23, 35),
            partStartTime: '23:30',
            partEndTime: '07:30',
          ),
        ],
      );

      final picked = AttendanceDay.pickCurrent([
        day,
      ], DateTime(2026, 11, 17, 2));

      expect(picked.openSession?.label, '23:30–07:30');
    });

    test('a closed session is never it', () {
      final day = closed(today);

      expect(day.openSession, isNull);
      expect(day.nextAction, ClockAction.clockIn);
    });
  });

  group('crossesMidnight', () {
    bool crosses(String? start, String? end) => AttendanceSession(
      partStartTime: start,
      partEndTime: end,
    ).crossesMidnight;

    test('an end not after the start crosses', () {
      expect(crosses('23:30', '07:30'), isTrue);
      expect(crosses('22:00:00', '06:00:00'), isTrue);
      // The backend's rule: equal times are a full day, which crosses.
      expect(crosses('08:00', '08:00'), isTrue);
    });

    test('an end after the start does not', () {
      expect(crosses('08:00', '17:00'), isFalse);
      expect(crosses('00:00', '08:00'), isFalse);
      expect(crosses('08:00', '08:00:01'), isFalse);
    });

    test('a missing or unreadable time is not a night shift', () {
      expect(crosses(null, '07:30'), isFalse);
      expect(crosses('23:30', null), isFalse);
      expect(crosses('late', '07:30'), isFalse);
      expect(crosses('23:30', '7'), isFalse);
      expect(crosses('25:00', '07:30'), isFalse);
    });
  });
}
