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
  const OffsiteClockOut(this.checkIn);

  final OffsiteRequestDetail checkIn;
}

/// The check-in and its check-out both wait for approval. Nothing to clock
/// out; the slide stays on a normal clock-in (the server answers if one is
/// not allowed then).
class WaitingBoth extends NextPunch {
  const WaitingBoth(this.checkIn);

  final OffsiteRequestDetail checkIn;
}

/// The one decision, in this order:
/// 1. an open session in today's record ([clockedIn], #7's rule) → normal
///    clock-out;
/// 2. an open OT clock-in ([otOpen], #34) → normal clock-out;
/// 3. a waiting off-site check-in scanned [today] or the day before, with no
///    waiting check-out paired to it → off-site clock-out;
/// 4. one with its check-out also waiting → [WaitingBoth];
/// 5. else a normal clock-in.
///
/// A check-out pairs with a check-in of the same session when it was
/// scanned the check-in's day or the next (a 22:00 Monday check-in and its
/// 06:00 Tuesday check-out carry different dates) and after it.
NextPunch nextPunch({
  required bool clockedIn,
  required bool otOpen,
  required List<OffsiteRequestDetail> waiting,
  required DateTime today,
}) {
  if (clockedIn || otOpen) return const NormalClockOut();

  final day = _date(today);
  final yesterday = DateTime(day.year, day.month, day.day - 1);
  final checkIns = [
    for (final r in waiting)
      if (_waitingAs(r, OffsiteMethod.checkIn) &&
          (r.scanDate == null
              ? false
              : _date(r.scanDate!) == day || _date(r.scanDate!) == yesterday))
        r,
  ]..sort((a, b) => _when(b).compareTo(_when(a)));
  final checkOuts = [
    for (final r in waiting)
      if (_waitingAs(r, OffsiteMethod.checkOut)) r,
  ];

  OffsiteRequestDetail? paired;
  for (final checkIn in checkIns) {
    final hasCheckOut = checkOuts.any((out) => _pairs(checkIn, out));
    if (!hasCheckOut) return OffsiteClockOut(checkIn);
    paired ??= checkIn;
  }
  if (paired != null) return WaitingBoth(paired);
  return const NormalClockIn();
}

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

/// When the scan was made: its time, or when it was sent.
DateTime _when(OffsiteRequestDetail r) => r.scanTimestamp ?? r.submittedAt;

DateTime _date(DateTime t) => DateTime(t.year, t.month, t.day);
