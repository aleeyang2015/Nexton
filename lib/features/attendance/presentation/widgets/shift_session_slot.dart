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

  /// One slot per shift segment, in the profile's order.
  ///
  /// A session is matched to its segment by the start time in its
  /// `session_label` (`"08:00–12:00"` ↔ `start_time: "08:00:00"`), so an
  /// afternoon-only day still lands in the afternoon tile. A session with no
  /// readable label falls back to its position in the day.
  static List<ShiftSessionSlot> build(
    List<ShiftDetail> details,
    List<AttendanceSession> sessions,
  ) {
    return [
      for (var i = 0; i < details.length; i++)
        ShiftSessionSlot(
          detail: details[i],
          session: _sessionFor(details[i], i, sessions),
        ),
    ];
  }

  static AttendanceSession? _sessionFor(
    ShiftDetail detail,
    int index,
    List<AttendanceSession> sessions,
  ) {
    final start = _startOf(detail.startTime);
    if (start != null) {
      for (final session in sessions) {
        if (_startOf(session.label) == start) return session;
      }
    }

    if (index < sessions.length && _startOf(sessions[index].label) == null) {
      return sessions[index];
    }
    return null;
  }

  /// The first `HH:mm` in [raw], or null when there is none.
  static String? _startOf(String? raw) {
    if (raw == null) return null;
    return RegExp(r'\d{2}:\d{2}').firstMatch(raw)?.group(0);
  }
}
