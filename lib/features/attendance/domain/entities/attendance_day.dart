import 'package:equatable/equatable.dart';
import '../../../profile/domain/entities/shift_detail.dart';

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
  /// The name of the shift part this session belongs to, as HR named it
  /// (`shift_detail.name` / `name_lo`): "Morning" / "ກະເຊົ້າ". Null for a
  /// punch outside any shift part; a row then falls back to its position.
  final String? partName;
  final String? partNameLo;

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
  /// line. They are the clock-in's, or the clock-out's for a session that has
  /// only a clock-out. Either can be null; the row hides what it doesn't have.
  final String? method;
  final String? locationLabel;

  /// The part's id (`shift_detail.id`): what a "forgot to scan" request
  /// for this session sends as `shift_detail_id` (#44).
  final String? partId;

  /// When this session's shift part starts and ends, as the company's wall
  /// clock reads (`HH:MM` or `HH:MM:SS`). Null when the record carries no
  /// shift part for the session.
  final String? partStartTime;
  final String? partEndTime;

  const AttendanceSession({
    this.partName,
    this.partNameLo,
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
    this.partStartTime,
    this.partEndTime,
    this.partId,
  });

  /// Punched in and not yet out — the session a clock-out would close.
  bool get isOpen => clockIn != null && clockOut == null;

  /// True for a part that runs past midnight: both times are known and the
  /// end is not after the start (23:30–07:30, or a full 24 hours). This is
  /// the backend's own rule, so the App and the server agree on which
  /// sessions belong to a night shift.
  bool get crossesMidnight {
    final start = _secondsOfDay(partStartTime);
    final end = _secondsOfDay(partEndTime);
    if (start == null || end == null) return false;
    return end <= start;
  }

  /// `HH:MM[:SS]` as seconds since midnight, or null when it is not a time.
  static int? _secondsOfDay(String? time) {
    if (time == null) return null;
    final parts = time.trim().split(':');
    if (parts.length < 2 || parts.length > 3) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    final second = parts.length == 3 ? int.tryParse(parts[2]) : 0;
    if (hour == null || minute == null || second == null) return null;
    if (hour < 0 || hour > 24 || minute < 0 || minute > 59) return null;
    if (second < 0 || second > 59) return null;

    return hour * 3600 + minute * 60 + second;
  }

  bool get isComplete => clockIn != null && clockOut != null;

  /// This session's part as far as the record knows it (#44): its id,
  /// names and times; the profile's part, when it has one, knows more (the
  /// weekday rows and the minutes). Null when the record names no part.
  ShiftDetail? get part => partId == null
      ? null
      : ShiftDetail(
          id: partId,
          name: partName,
          nameLo: partNameLo,
          startTime: partStartTime,
          endTime: partEndTime,
        );

  @override
  List<Object?> get props => [
    partName,
    partNameLo,
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
    partId,
    partStartTime,
    partEndTime,
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

  /// Approved OT hours clocked on this day, as the server counted them; 0
  /// when there is none. Never worked out from [totalWorkHours]: a long day
  /// without approved OT is not OT.
  final double overtimeHours;

  const AttendanceDay({
    this.date,
    this.status,
    this.sessions = const [],
    this.totalWorkHours,
    this.overtimeHours = 0,
  });

  /// The state to assume before `records/my` has answered — and the state a
  /// day with no punches is genuinely in.
  static const empty = AttendanceDay();

  /// The record the home card is about at [now], out of the records around
  /// it.
  ///
  /// It is not always the one dated today. The backend files a punch under
  /// the shift whose window holds it, even across midnight: 23:50 for a 00:00
  /// shift lands on **tomorrow's** record, and a night shift's open session
  /// lives on the day it **started**. So, in this order:
  ///
  /// 1. tomorrow's record with an open session;
  /// 2. today's record with an open session;
  /// 3. yesterday's record with an open session whose part crosses midnight
  ///    (a night shift still running);
  /// 4. today's record;
  /// 5. [empty].
  ///
  /// A day-shift session left open yesterday is never picked: the employee
  /// forgot to clock out, and today's card must still offer clock-in. A
  /// record with no date cannot be placed and is ignored.
  static AttendanceDay pickCurrent(List<AttendanceDay> rows, DateTime now) {
    // Calendar arithmetic, not `Duration(days: 1)`: a day is not always 24
    // hours where clocks change.
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    AttendanceDay? on(DateTime day) {
      for (final row in rows) {
        final date = row.date;
        if (date == null) continue;
        if (date.year == day.year &&
            date.month == day.month &&
            date.day == day.day) {
          return row;
        }
      }
      return null;
    }

    final tomorrowRow = on(tomorrow);
    if (tomorrowRow != null && tomorrowRow.isClockedIn) return tomorrowRow;

    final todayRow = on(today);
    if (todayRow != null && todayRow.isClockedIn) return todayRow;

    final yesterdayRow = on(yesterday);
    if (yesterdayRow != null &&
        yesterdayRow.sessions.any((s) => s.isOpen && s.crossesMidnight)) {
      return yesterdayRow;
    }

    return todayRow ?? empty;
  }

  /// The session a clock-out would close, if any: the open one that was
  /// opened last. An earlier session left open by a forgotten clock-out (the
  /// day part, on a record picked for its night part) is not the one the
  /// employee is in now.
  AttendanceSession? get openSession {
    AttendanceSession? latest;
    for (final session in sessions) {
      if (!session.isOpen) continue;
      if (latest == null || session.clockIn!.isAfter(latest.clockIn!)) {
        latest = session;
      }
    }
    return latest;
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
    double? overtimeHours,
  }) => AttendanceDay(
    date: date ?? this.date,
    status: status ?? this.status,
    sessions: sessions ?? this.sessions,
    totalWorkHours: totalWorkHours ?? this.totalWorkHours,
    overtimeHours: overtimeHours ?? this.overtimeHours,
  );

  @override
  List<Object?> get props => [
    date,
    status,
    sessions,
    totalWorkHours,
    overtimeHours,
  ];
}
