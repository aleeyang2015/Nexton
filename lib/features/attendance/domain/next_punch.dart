import 'entities/offsite_detail.dart';
import 'entities/offsite_method.dart';
import 'entities/time_correction_status.dart';

/// What the slide does next (#41): a normal punch, or an off-site clock-out
/// for a check-in that still waits for its approvers. Plain Dart.
sealed class NextPunch {
  const NextPunch();
}

/// Clock in through the phone door.
class NormalClockIn extends NextPunch {
  const NormalClockIn();
}

/// Clock out through the phone door: today's record has an open session, or
/// an OT clock-in is open.
class NormalClockOut extends NextPunch {
  const NormalClockOut();
}

/// Clock out as an off-site request: [checkIn] waits for approval, so the
/// server has no open session to close; it pairs the off-site check-out
/// with this check-in.
class OffsiteClockOut extends NextPunch {
  const OffsiteClockOut(this.checkIn, {this.until});

  final OffsiteRequestDetail checkIn;

  /// When this stops being offered: [pairReach] after a check-in from
  /// yesterday. Null for today's check-in: it holds until the day ends.
  final DateTime? until;
}

/// The check-in and its check-out both wait for approval. Nothing to clock
/// out; the slide stays on a normal clock-in (the server answers if one is
/// not allowed then).
class WaitingBoth extends NextPunch {
  const WaitingBoth(this.checkIn);

  final OffsiteRequestDetail checkIn;
}

/// A check-in from yesterday, still waiting, but past [pairReach]: the
/// server may no longer pair a check-out with it, so the slide is back on a
/// normal clock-in. The card still says it waits.
class WaitingCheckIn extends NextPunch {
  const WaitingCheckIn(this.checkIn);

  final OffsiteRequestDetail checkIn;
}

/// The one decision, in this order:
/// 1. an open session in today's record ([clockedIn], #7's rule) → normal
///    clock-out;
/// 2. an open OT clock-in ([otOpen], #34) → normal clock-out;
/// 3. a waiting off-site check-in scanned [today] — or the day before when
///    its shift crosses midnight (a night shift still running) — with no
///    waiting check-out paired to it → off-site clock-out; one from the day
///    before only up to [pairReach] after the scan (owner, 21 Nov 2026),
///    then [WaitingCheckIn]. A day shift's check-in from yesterday that was
///    never closed does not hold today's slide on "clock out": today starts
///    with a normal clock-in, and the server decides;
/// 4. one from the day before with no shift times (a scan on a rest day, or
///    its part deleted; owner decision on #41, 19 Nov 2026) → off-site
///    clock-out up to [pairReach] after the scan; after that
///    [WaitingCheckIn];
/// 5. one with its check-out also waiting → [WaitingBoth];
/// 6. a check-in past its reach (4) → [WaitingCheckIn];
/// 7. else a normal clock-in.
///
/// [today] is the day the waiting scans were read for; [now] the time.
///
/// A check-out pairs with a check-in of the same session when it was
/// scanned the check-in's day or the next (a 22:00 Monday check-in and its
/// 06:00 Tuesday check-out carry different dates) and after it.
NextPunch nextPunch({
  required bool clockedIn,
  required bool otOpen,
  required List<OffsiteRequestDetail> waiting,
  required DateTime today,
  required DateTime now,
}) {
  if (clockedIn || otOpen) return const NormalClockOut();

  final day = _date(today);
  final yesterday = DateTime(day.year, day.month, day.day - 1);
  final checkIns = [
    for (final r in waiting)
      if (_waitingAs(r, OffsiteMethod.checkIn) &&
          r.scanDate != null &&
          (_date(r.scanDate!) == day ||
              (_date(r.scanDate!) == yesterday &&
                  (_crossesMidnight(r) || !_hasShiftTimes(r)))))
        r,
  ]..sort((a, b) => _when(b).compareTo(_when(a)));
  final checkOuts = [
    for (final r in waiting)
      if (_waitingAs(r, OffsiteMethod.checkOut)) r,
  ];

  OffsiteRequestDetail? paired;
  OffsiteRequestDetail? pastReach;
  for (final checkIn in checkIns) {
    if (checkOuts.any((out) => _pairs(checkIn, out))) {
      paired ??= checkIn;
      continue;
    }
    // Yesterday's scan has a reach, a night shift's too (owner, 21 Nov
    // 2026); today's scan holds the whole day.
    final until = _date(checkIn.scanDate!) == yesterday
        ? _when(checkIn).add(pairReach)
        : null;
    if (until == null) return OffsiteClockOut(checkIn);
    if (!now.isAfter(until)) return OffsiteClockOut(checkIn, until: until);
    pastReach ??= checkIn;
  }
  if (paired != null) return WaitingBoth(paired);
  if (pastReach != null) return WaitingCheckIn(pastReach);
  return const NormalClockIn();
}

/// How long after yesterday's scan the slide still offers an off-site
/// check-out for it. The server pairs one for `openReach`: 18 h for a scan
/// with no shift part, and never less for one with a part (`openReachSQL`'s
/// floor; longer only for a part over 14 h, or with late-checkout minutes or
/// early-checkin minutes over 4 h). The App is not sent those minutes, so it
/// stops at the floor: it never offers a check-out the server refuses (#41).
const pairReach = Duration(hours: 18);

bool _waitingAs(OffsiteRequestDetail r, OffsiteMethod method) =>
    r.method == method && r.status == TimeCorrectionStatus.pending;

bool _pairs(OffsiteRequestDetail checkIn, OffsiteRequestDetail out) {
  if (out.sessionOrder != checkIn.sessionOrder) return false;
  final inDate = checkIn.scanDate;
  final outDate = out.scanDate;
  if (inDate == null || outDate == null) return false;
  final d = _date(inDate);
  final next = DateTime(d.year, d.month, d.day + 1);
  final o = _date(outDate);
  if (o != d && o != next) return false;
  return !_when(out).isBefore(_when(checkIn));
}

/// When the scan was made: its time, or when it was sent; in local time
/// (a time sent as an instant in UTC is turned into the phone's).
DateTime _when(OffsiteRequestDetail r) =>
    (r.scanTimestamp ?? r.submittedAt).toLocal();

/// The scan carries both its shift's start and end.
bool _hasShiftTimes(OffsiteRequestDetail r) =>
    r.shift?.start != null && r.shift?.end != null;

/// The scan's shift ends at or before it starts: it runs past midnight.
bool _crossesMidnight(OffsiteRequestDetail r) {
  final start = r.shift?.start;
  final end = r.shift?.end;
  return start != null && end != null && end <= start;
}

DateTime _date(DateTime t) => DateTime(t.year, t.month, t.day);
