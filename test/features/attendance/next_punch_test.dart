import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/features/attendance/domain/entities/offsite_method.dart';
import 'package:next_on/features/attendance/domain/entities/time_correction_detail.dart';
import 'package:next_on/features/attendance/domain/entities/time_correction_status.dart';
import 'package:next_on/features/attendance/domain/next_punch.dart';

import '../../support/attendance_test_doubles.dart';

/// What the slide does next (#41).
void main() {
  final today = DateTime(2026, 11, 17, 17);
  final monday = DateTime(2026, 11, 16);

  NextPunch decide(
    List waiting, {
    bool clockedIn = false,
    bool otOpen = false,
    DateTime? now,
  }) => nextPunch(
    clockedIn: clockedIn,
    otOpen: otOpen,
    waiting: [...waiting],
    today: now ?? today,
    now: now ?? today,
  );

  final checkInToday = waitingOffsite(
    method: OffsiteMethod.checkIn,
    at: DateTime(2026, 11, 17, 8),
  );

  test('nothing waiting, nothing open: a normal clock-in', () {
    expect(decide([]), isA<NormalClockIn>());
  });

  test('an open session in today\'s record wins: normal clock-out', () {
    expect(decide([checkInToday], clockedIn: true), isA<NormalClockOut>());
  });

  test('an open OT clock-in: normal clock-out', () {
    expect(decide([checkInToday], otOpen: true), isA<NormalClockOut>());
  });

  test('a check-in from today waiting: an off-site clock-out for it', () {
    final next = decide([checkInToday]);
    expect(next, isA<OffsiteClockOut>());
    expect((next as OffsiteClockOut).checkIn.id, 'off-1');
  });

  test('yesterday\'s night-shift check-in (22:00) waiting: still an off-site '
      'clock-out after midnight', () {
    final night = waitingOffsite(
      method: OffsiteMethod.checkIn,
      at: DateTime(2026, 11, 16, 22),
      shift: nightShift,
    );
    expect(
      decide([night], now: DateTime(2026, 11, 17, 6)),
      isA<OffsiteClockOut>(),
    );
  });

  test('a check-in from two days ago no longer counts', () {
    final old = waitingOffsite(
      method: OffsiteMethod.checkIn,
      at: DateTime(2026, 11, 15, 8),
    );
    expect(decide([old]), isA<NormalClockIn>());
  });

  test('both waiting for the same session: waitingBoth, the slide stays on '
      'a normal clock-in', () {
    final out = waitingOffsite(
      id: 'off-2',
      method: OffsiteMethod.checkOut,
      at: DateTime(2026, 11, 17, 17),
    );
    final next = decide([checkInToday, out]);
    expect(next, isA<WaitingBoth>());
  });

  test('a night shift: Monday 22:00 in, Tuesday 06:00 out, both waiting → '
      'waitingBoth, not another clock-out', () {
    final inMon = waitingOffsite(
      method: OffsiteMethod.checkIn,
      at: DateTime(2026, 11, 16, 22),
      shift: nightShift,
    );
    final outTue = waitingOffsite(
      id: 'off-2',
      method: OffsiteMethod.checkOut,
      at: DateTime(2026, 11, 17, 6),
    );
    expect(
      decide([inMon, outTue], now: DateTime(2026, 11, 17, 7)),
      isA<WaitingBoth>(),
    );
  });

  test('a waiting check-out for another session does not pair', () {
    final otherSession = waitingOffsite(
      id: 'off-2',
      method: OffsiteMethod.checkOut,
      at: DateTime(2026, 11, 17, 12),
      sessionOrder: 2,
    );
    expect(decide([checkInToday, otherSession]), isA<OffsiteClockOut>());
  });

  test('a check-out made before the check-in does not pair', () {
    final earlier = waitingOffsite(
      id: 'off-2',
      method: OffsiteMethod.checkOut,
      at: DateTime(2026, 11, 17, 7),
    );
    expect(decide([checkInToday, earlier]), isA<OffsiteClockOut>());
  });

  test('a check-out two days after does not pair', () {
    final inMon = waitingOffsite(
      method: OffsiteMethod.checkIn,
      at: monday.add(const Duration(hours: 8)),
    );
    final outWed = waitingOffsite(
      id: 'off-2',
      method: OffsiteMethod.checkOut,
      at: DateTime(2026, 11, 18, 8),
    );
    expect(
      decide([inMon, outWed], now: DateTime(2026, 11, 16, 9)),
      isA<OffsiteClockOut>(),
    );
  });

  test('yesterday\'s day-shift check-in never closed: today is a normal '
      'clock-in, not a day stuck on "clock out"', () {
    final dayMon = waitingOffsite(
      method: OffsiteMethod.checkIn,
      at: DateTime(2026, 11, 16, 8),
      shift: dayShift,
    );
    expect(
      decide([dayMon], now: DateTime(2026, 11, 17, 8)),
      isA<NormalClockIn>(),
    );
  });

  group(
    'yesterday\'s check-in with no shift times (owner decision, 19 Nov)',
    () {
      // Noy checks in off-site at 20:00 on a day with no shift.
      final noShift = waitingOffsite(
        method: OffsiteMethod.checkIn,
        at: DateTime(2026, 11, 16, 20),
      );

      test('17 h later: an off-site clock-out', () {
        final next = decide([noShift], now: DateTime(2026, 11, 17, 13));
        expect(next, isA<OffsiteClockOut>());
        expect((next as OffsiteClockOut).checkIn.id, 'off-1');
      });

      test('exactly 18 h later: still an off-site clock-out', () {
        expect(
          decide([noShift], now: DateTime(2026, 11, 17, 14)),
          isA<OffsiteClockOut>(),
        );
      });

      test('19 h later: a normal clock-in, and the check-in still shown', () {
        final next = decide([noShift], now: DateTime(2026, 11, 17, 15));
        expect(next, isA<WaitingCheckIn>());
        expect((next as WaitingCheckIn).checkIn.id, 'off-1');
      });

      test('a shift sent without its times counts as no shift times', () {
        final noTimes = waitingOffsite(
          method: OffsiteMethod.checkIn,
          at: DateTime(2026, 11, 16, 20),
          shift: const TimeCorrectionShift(name: 'Rest day'),
        );
        expect(
          decide([noTimes], now: DateTime(2026, 11, 17, 13)),
          isA<OffsiteClockOut>(),
        );
        expect(
          decide([noTimes], now: DateTime(2026, 11, 17, 15)),
          isA<WaitingCheckIn>(),
        );
      });

      test(
        'no scan time: the 18 h run from when it was sent (UTC, as local)',
        () {
          final sent = waitingOffsite(
            method: OffsiteMethod.checkIn,
            at: DateTime(2026, 11, 16, 20),
            noScanTime: true,
            submittedAt: DateTime(2026, 11, 16, 20).toUtc(),
          );
          expect(
            decide([sent], now: DateTime(2026, 11, 17, 13)),
            isA<OffsiteClockOut>(),
          );
          expect(
            decide([sent], now: DateTime(2026, 11, 17, 15)),
            isA<WaitingCheckIn>(),
          );
        },
      );

      test('its check-out also waiting: waitingBoth', () {
        final out = waitingOffsite(
          id: 'off-2',
          method: OffsiteMethod.checkOut,
          at: DateTime(2026, 11, 17, 7),
        );
        expect(
          decide([noShift, out], now: DateTime(2026, 11, 17, 15)),
          isA<WaitingBoth>(),
        );
      });

      test('today\'s pair waiting beside it: waitingBoth for today\'s', () {
        final inToday = waitingOffsite(
          id: 'off-2',
          method: OffsiteMethod.checkIn,
          at: DateTime(2026, 11, 17, 8),
        );
        final outToday = waitingOffsite(
          id: 'off-3',
          method: OffsiteMethod.checkOut,
          at: DateTime(2026, 11, 17, 12),
        );
        final next = decide([
          noShift,
          inToday,
          outToday,
        ], now: DateTime(2026, 11, 17, 15));
        expect(next, isA<WaitingBoth>());
        expect((next as WaitingBoth).checkIn.id, 'off-2');
      });

      test('an open session in the record still wins', () {
        expect(
          decide([noShift], clockedIn: true, now: DateTime(2026, 11, 17, 15)),
          isA<NormalClockOut>(),
        );
      });

      group('a night shift from yesterday stops at 18 h too (owner, 21 Nov)',
          () {
        // Lee checks in off-site at 22:00 Monday on a 22:00–06:00 shift and
        // never checks out. The server pairs a check-out with it for at least
        // 18 h (openReach's floor), so the slide offers it that long, then
        // goes back to a normal clock-in for Tuesday's shift.
        final night = waitingOffsite(
          method: OffsiteMethod.checkIn,
          at: DateTime(2026, 11, 16, 22),
          shift: nightShift,
        );

        test('17 h later: an off-site clock-out that says when it stops', () {
          final next = decide([night], now: DateTime(2026, 11, 17, 15));
          expect(next, isA<OffsiteClockOut>());
          expect((next as OffsiteClockOut).until, DateTime(2026, 11, 17, 16));
        });

        test('exactly 18 h later: still an off-site clock-out', () {
          expect(
            decide([night], now: DateTime(2026, 11, 17, 16)),
            isA<OffsiteClockOut>(),
          );
        });

        test('18 h and a second later: a normal clock-in, still shown', () {
          final next = decide([night], now: DateTime(2026, 11, 17, 16, 0, 1));
          expect(next, isA<WaitingCheckIn>());
          expect((next as WaitingCheckIn).checkIn.id, 'off-1');
        });
        test('scanned after midnight (00:30, dated today): 18 h, then a '
            'normal clock-in for tonight', () {
          // The server dates a scan by its own calendar day, so 00:30 Tuesday
          // is Tuesday's; it stops pairing at 18:30.
          final late = waitingOffsite(
            method: OffsiteMethod.checkIn,
            at: DateTime(2026, 11, 17, 0, 30),
            shift: nightShift,
          );
          final before = decide([late], now: DateTime(2026, 11, 17, 18, 30));
          expect(before, isA<OffsiteClockOut>());
          expect(
            (before as OffsiteClockOut).until,
            DateTime(2026, 11, 17, 18, 30),
          );
          expect(
            decide([late], now: DateTime(2026, 11, 17, 18, 30, 1)),
            isA<WaitingCheckIn>(),
          );
        });
      });

      test('within 18 h: the clock-out says when it stops', () {
        final next = decide([noShift], now: DateTime(2026, 11, 17, 13));
        expect((next as OffsiteClockOut).until, DateTime(2026, 11, 17, 14));
      });

      test('from two days ago: not shown', () {
        expect(
          decide([noShift], now: DateTime(2026, 11, 18, 9)),
          isA<NormalClockIn>(),
        );
      });
    },
  );

  test('a time sent as UTC (created_at, no scan time) is compared as local',
      () {
    final inLocal = waitingOffsite(
      method: OffsiteMethod.checkIn,
      at: DateTime(2026, 11, 17, 8),
    );
    // Sent at 09:00 local, as an instant in UTC.
    final outUtc = waitingOffsite(
      id: 'off-2',
      method: OffsiteMethod.checkOut,
      at: DateTime(2026, 11, 17, 9),
      noScanTime: true,
      submittedAt: DateTime(2026, 11, 17, 9).toUtc(),
    );
    expect(decide([inLocal, outUtc]), isA<WaitingBoth>());
  });

  test('a decided check-in (approved, rejected) is not waiting', () {
    final approved = waitingOffsite(
      method: OffsiteMethod.checkIn,
      at: DateTime(2026, 11, 17, 8),
      status: TimeCorrectionStatus.approved,
    );
    expect(decide([approved]), isA<NormalClockIn>());
  });
}
