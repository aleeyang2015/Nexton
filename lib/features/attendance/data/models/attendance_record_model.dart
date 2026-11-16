import '../../domain/entities/attendance_day.dart';

/// Reads one record from `GET /attendance/records/my`.
///
/// The keys are the backend's own, from `AttendanceRecordResponse` and
/// `SessionResponse` in its `attendance/types.go`: no aliases, no guesses. A
/// key read here that the backend does not send would be a field that is
/// silently always empty, which is how the history rows once lost their
/// shift part, method and place.
class AttendanceRecordModel {
  const AttendanceRecordModel._();

  static AttendanceDay fromJson(Map<String, dynamic> json) {
    final rawSessions = json['sessions'];

    return AttendanceDay(
      date: _dateTime(json['date']),
      status: _nonEmpty(_string(json['status'])),
      sessions: rawSessions is List
          ? rawSessions
                .whereType<Map>()
                .map((s) => _session(Map<String, dynamic>.from(s)))
                .toList(growable: false)
          : const [],
      totalWorkHours: _double(json['work_hours']),
    );
  }

  static AttendanceSession _session(Map<String, dynamic> json) {
    // The shift part this session belongs to; null for a punch outside any.
    final part = json['shift_detail'];
    final partJson = part is Map ? part : const <dynamic, dynamic>{};

    return AttendanceSession(
      partName: _nonEmpty(_string(partJson['name'])),
      partNameLo: _nonEmpty(_string(partJson['name_lo'])),
      clockIn: _dateTime(json['clock_in']),
      clockOut: _dateTime(json['clock_out']),
      isLate: json['is_late'] == true,
      isEarlyExit: json['is_early_exit'] == true,
      lateMinutes: _int(json['late_minutes']),
      earlyExitMinutes: _int(json['early_exit_minutes']),
      workHours: _double(json['work_hours']),
      status: _nonEmpty(_string(json['status'])),
      // The clock-in's, else the clock-out's: a session with only a clock-out
      // still says how and where that punch was made.
      method:
          _nonEmpty(_string(json['clock_in_method'])) ??
          _nonEmpty(_string(json['clock_out_method'])),
      locationLabel:
          _nonEmpty(_string(json['clock_in_location_name'])) ??
          _nonEmpty(_string(json['clock_out_location_name'])),
      partStartTime: _nonEmpty(_string(partJson['start_time'])),
      partEndTime: _nonEmpty(_string(partJson['end_time'])),
    );
  }

  /// UTC in, local out — the same one-place conversion the receipts get.
  static DateTime? _dateTime(dynamic value) {
    final text = _string(value);
    if (text == null || text.isEmpty) return null;
    return DateTime.tryParse(text)?.toLocal();
  }

  static String? _string(dynamic value) => value is String ? value : null;

  /// Blank text is no text: a name or a place made only of spaces must not
  /// stand in for a real one, nor leave a row with an empty label.
  static String? _nonEmpty(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static double? _double(dynamic value) => (value as num?)?.toDouble();

  static int? _int(dynamic value) => (value as num?)?.toInt();
}
