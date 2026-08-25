import 'package:equatable/equatable.dart';

/// Which punch the employee owes next. The card's slide action reads this to
/// decide its label and which endpoint to hit.
///
/// §7 rule 4 is explicit that this is a *hint*: the backend's session guard is
/// the final authority, so a wrong guess here surfaces as a [PunchBlocked]
/// rather than a corrupt record.
enum ClockAction { clockIn, clockOut }

/// One block of a shift — a day can be split (08:00–12:00, 13:30–17:30), and
/// each block is punched in and out independently (§6.2).
class AttendanceSession extends Equatable {
  final int? order;

  /// e.g. `08:00–12:00`. §5's note recommends showing this rather than
  /// [order], which is 0-based in error details but not in records.
  final String? label;

  /// Local time; the API sends UTC.
  final DateTime? clockIn;
  final DateTime? clockOut;

  final bool isLate;
  final bool isEarlyExit;

  /// Minutes late / minutes left early, when the backend reports them.
  /// `late_minutes` is the confirmed wire key — `PunchReceiptModel` already
  /// reads it off the clock-in response; the history list is the same
  /// number, just from a different endpoint.
  final int? lateMinutes;
  final int? earlyExitMinutes;

  final double? workHours;
  final String? status;

  /// How the punch was made (`gps`, `wifi`, …) and where, when the backend
  /// reports them on the record — the history list's "GPS · Office Center"
  /// line. Either can be null; the row hides what it doesn't have.
  final String? method;
  final String? locationLabel;

  const AttendanceSession({
    this.order,
    this.label,
    this.clockIn,
    this.clockOut,
    this.isLate = false,
    this.isEarlyExit = false,
    this.lateMinutes,
    this.earlyExitMinutes,
    this.workHours,
    this.status,
    this.method,
    this.locationLabel,
  });

  /// Punched in and not yet out — the session a clock-out would close.
  bool get isOpen => clockIn != null && clockOut == null;

  bool get isComplete => clockIn != null && clockOut != null;

  @override
  List<Object?> get props => [
    order,
    label,
    clockIn,
    clockOut,
    isLate,
    isEarlyExit,
    lateMinutes,
    earlyExitMinutes,
    workHours,
    status,
    method,
    locationLabel,
  ];
}

/// One day's attendance record, assembled from its sessions.
///
/// This is what lets the card show the truth on a cold start instead of
/// waiting for the user to punch — the production checklist in the spec calls
/// for exactly that ("แยก UI ปุ่ม clock-in / clock-out ตามสถานะปัจจุบัน
/// (ดึงจาก records/my ล่าสุด)").
class AttendanceDay extends Equatable {
  final DateTime? date;
  final String? status;
  final List<AttendanceSession> sessions;
  final double? totalWorkHours;

  const AttendanceDay({
    this.date,
    this.status,
    this.sessions = const [],
    this.totalWorkHours,
  });

  /// The state to assume before `records/my` has answered — and the state a
  /// day with no punches is genuinely in.
  static const empty = AttendanceDay();

  /// The session a clock-out would close, if any.
  AttendanceSession? get openSession {
    for (final session in sessions) {
      if (session.isOpen) return session;
    }
    return null;
  }

  /// True while a session is open. Drives the card's status dot.
  bool get isClockedIn => openSession != null;

  /// What the slide action should do next.
  ClockAction get nextAction =>
      isClockedIn ? ClockAction.clockOut : ClockAction.clockIn;

  /// Earliest clock-in of the day — the "time in" the card shows.
  DateTime? get firstClockIn {
    DateTime? earliest;
    for (final session in sessions) {
      final at = session.clockIn;
      if (at == null) continue;
      if (earliest == null || at.isBefore(earliest)) earliest = at;
    }
    return earliest;
  }

  /// Latest clock-out of the day — the "time out" the card shows.
  DateTime? get lastClockOut {
    DateTime? latest;
    for (final session in sessions) {
      final at = session.clockOut;
      if (at == null) continue;
      if (latest == null || at.isAfter(latest)) latest = at;
    }
    return latest;
  }

  /// True when nothing has been punched today.
  bool get isUntouched => firstClockIn == null && lastClockOut == null;

  /// Day-level rollups for the history list, where a day shows one status
  /// even though it can hold several sessions.
  bool get isLate => sessions.any((s) => s.isLate);

  bool get isEarlyExit => sessions.any((s) => s.isEarlyExit);

  /// The first late session's minutes — a day is "late" from whichever
  /// session opened it late, typically the morning one.
  int? get lateMinutes {
    for (final session in sessions) {
      if (session.isLate && session.lateMinutes != null) {
        return session.lateMinutes;
      }
    }
    return null;
  }

  /// The last early-exit session's minutes — early exit is a closing-time
  /// concern, so the latest session that left early wins.
  int? get earlyExitMinutes {
    for (final session in sessions.reversed) {
      if (session.isEarlyExit && session.earlyExitMinutes != null) {
        return session.earlyExitMinutes;
      }
    }
    return null;
  }

  AttendanceDay copyWith({
    DateTime? date,
    String? status,
    List<AttendanceSession>? sessions,
    double? totalWorkHours,
  }) => AttendanceDay(
    date: date ?? this.date,
    status: status ?? this.status,
    sessions: sessions ?? this.sessions,
    totalWorkHours: totalWorkHours ?? this.totalWorkHours,
  );

  @override
  List<Object?> get props => [date, status, sessions, totalWorkHours];
}
