import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/features/attendance/domain/entities/offsite_method.dart';
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
      decide([inMon, outWed], now: DateTime(2026, 11, 17, 9)),
      isA<OffsiteClockOut>(),
    );
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
