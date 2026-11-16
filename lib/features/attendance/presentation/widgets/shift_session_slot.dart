import '../../../../features/profile/domain/entities/shift_detail.dart';
import '../../domain/entities/attendance_day.dart';

/// One segment of the employee's assigned shift, paired with today's punches
/// for it — what one tile of the card's session grid shows.
class ShiftSessionSlot {
  final ShiftDetail detail;

  /// Today's session for [detail], or null when it hasn't been punched.
  final AttendanceSession? session;

  const ShiftSessionSlot({required this.detail, this.session});

  DateTime? get clockIn => session?.clockIn;
  DateTime? get clockOut => session?.clockOut;

  /// Punched in and not yet out — the clock-out box reads "waiting".
  bool get isAwaitingClockOut => session?.isOpen ?? false;

  /// One slot per shift segment, in the profile's order. When two sessions
  /// land on the same segment, the first one wins.
  ///
  /// [day] is the date of the record the sessions belong to. With it, each
  /// segment's window is that weekday's own ([ShiftDetail.timesOn]), so a
  /// punch is placed against the hours the tile shows.
  static List<ShiftSessionSlot> build(
    List<ShiftDetail> details,
    List<AttendanceSession> sessions, {
    DateTime? day,
  }) {
    final windows = [
      for (final detail in details)
        day == null
            ? (start: detail.startTime, end: detail.endTime)
            : detail.timesOn(day),
    ];

    final bySegment = <int, AttendanceSession>{};
    for (final session in sessions) {
      final index = _segmentFor(session, windows, details);
      if (index != null) bySegment.putIfAbsent(index, () => session);
    }

    return [
      for (var i = 0; i < details.length; i++)
        ShiftSessionSlot(detail: details[i], session: bySegment[i]),
    ];
  }

  /// Which segment [session] belongs to, tried in order of how much the
  /// backend told us:
  ///
  /// 1. the start time of the shift part the backend filed it under
  ///    (`shift_detail.start_time`) — the backend's own assignment, matched
  ///    against the day's window and then against the part's usual start,
  ///    since either may be what the backend sent;
  /// 2. its clock-in time against the day's windows — a 12:00 clock-in on
  ///    an 08:00–12:00 / 13:00–17:00 day is an early start to the afternoon,
  ///    not the morning;
  /// 3. nothing — an unpunched session with no shift part isn't placed.
  ///
  /// The clock-in time is the last resort because it is a guess: when a
  /// weekday's row makes two windows overlap, only the backend's assignment
  /// says which part a punch belongs to.
  static int? _segmentFor(
    AttendanceSession session,
    List<({String? start, String? end})> windows,
    List<ShiftDetail> details,
  ) {
    final assigned = _minutesOf(session.partStartTime);
    if (assigned != null) {
      for (var i = 0; i < windows.length; i++) {
        if (_minutesOf(windows[i].start) == assigned) return i;
      }
      for (var i = 0; i < details.length; i++) {
        if (_minutesOf(details[i].startTime) == assigned) return i;
      }
    }

    final clockIn = session.clockIn;
    if (clockIn == null) return null;
    return _segmentAt(clockIn.hour * 60 + clockIn.minute, windows);
  }

  /// The segment whose `[start, end)` window holds [minute]; otherwise the
  /// next segment to start after it (an early clock-in for that segment);
  /// otherwise, past the last one, the segment that starts last.
  static int? _segmentAt(
    int minute,
    List<({String? start, String? end})> windows,
  ) {
    int? next;
    int? nextStart;
    int? last;
    int? lastStart;

    for (var i = 0; i < windows.length; i++) {
      final start = _minutesOf(windows[i].start);
      if (start == null) continue;
      final end = _minutesOf(windows[i].end);

      if (minute >= start && (end == null || minute < end)) return i;
      if (start > minute && (nextStart == null || start < nextStart)) {
        next = i;
        nextStart = start;
      }
      if (lastStart == null || start > lastStart) {
        last = i;
        lastStart = start;
      }
    }
    return next ?? last;
  }

  /// Minutes past midnight of the first `H:mm`/`HH:mm` in [raw], or null
  /// when there is none — so `"8:00-12:00"` reads the same as `"08:00"`.
  static int? _minutesOf(String? raw) {
    if (raw == null) return null;
    final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(raw);
    if (match == null) return null;
    return int.parse(match.group(1)!) * 60 + int.parse(match.group(2)!);
  }
}
