import '../../domain/entities/attendance_day.dart';

/// Reads one record from `GET /attendance/records/my` (§6.2).
///
/// §6 describes the record's contents but not its exact field spellings, so
/// each value is looked up under the names the rest of the API uses, with the
/// plainer alias accepted too. The cost of an alias is one map lookup; the
/// cost of guessing wrong is a card stuck on "not checked in".
class AttendanceRecordModel {
  const AttendanceRecordModel._();

  static AttendanceDay fromJson(Map<String, dynamic> json) {
    final rawSessions = json['sessions'];

    return AttendanceDay(
      date: _dateTime(json['date'] ?? json['work_date']),
      status: _nonEmpty(_string(json['status'])),
      sessions: rawSessions is List
          ? rawSessions
                .whereType<Map>()
                .map((s) => _session(Map<String, dynamic>.from(s)))
                .toList(growable: false)
          : const [],
      totalWorkHours: _double(json['total_work_hours'] ?? json['work_hours']),
    );
  }

  static AttendanceSession _session(Map<String, dynamic> json) {
    return AttendanceSession(
      order: _int(json['session_order'] ?? json['order']),
      label: _nonEmpty(_string(json['session_label'] ?? json['label'])),
      clockIn: _dateTime(json['clock_in'] ?? json['clock_in_at']),
      clockOut: _dateTime(json['clock_out'] ?? json['clock_out_at']),
      isLate: json['is_late'] == true,
      isEarlyExit: json['is_early_exit'] == true,
      workHours: _double(json['work_hours']),
      status: _nonEmpty(_string(json['status'])),
    );
  }

  /// UTC in, local out — the same one-place conversion the receipts get.
  static DateTime? _dateTime(dynamic value) {
    final text = _string(value);
    if (text == null || text.isEmpty) return null;
    return DateTime.tryParse(text)?.toLocal();
  }

  static String? _string(dynamic value) => value is String ? value : null;

  static String? _nonEmpty(String? value) =>
      (value == null || value.isEmpty) ? null : value;

  static double? _double(dynamic value) => (value as num?)?.toDouble();

  static int? _int(dynamic value) => (value as num?)?.toInt();
}
