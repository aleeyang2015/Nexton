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
  static List<ShiftSessionSlot> build(
    List<ShiftDetail> details,
    List<AttendanceSession> sessions,
  ) {
    final bySegment = <int, AttendanceSession>{};
    for (final session in sessions) {
      final index = _segmentFor(session, details);
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
  /// 1. the start time in its `session_label` (`"13:00–17:00"` ↔
  ///    `start_time: "13:00:00"`) — the backend's own assignment;
  /// 2. its clock-in time against the segment windows — a 12:00 clock-in on
  ///    an 08:00–12:00 / 13:00–17:00 day is an early start to the afternoon,
  ///    not the morning;
  /// 3. nothing — an unlabelled, unpunched session isn't placed.
  static int? _segmentFor(
    AttendanceSession session,
    List<ShiftDetail> details,
  ) {
    final labelStart = _minutesOf(session.label);
    if (labelStart != null) {
      for (var i = 0; i < details.length; i++) {
        if (_minutesOf(details[i].startTime) == labelStart) return i;
      }
    }

    final clockIn = session.clockIn;
    if (clockIn == null) return null;
    return _segmentAt(clockIn.hour * 60 + clockIn.minute, details);
  }

  /// The segment whose `[start, end)` window holds [minute]; otherwise the
  /// next segment to start after it (an early clock-in for that segment);
  /// otherwise, past the last one, the segment that starts last.
  static int? _segmentAt(int minute, List<ShiftDetail> details) {
    int? next;
    int? nextStart;
    int? last;
    int? lastStart;

    for (var i = 0; i < details.length; i++) {
      final start = _minutesOf(details[i].startTime);
      if (start == null) continue;
      final end = _minutesOf(details[i].endTime);

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
