import '../../domain/entities/attendance_summary.dart';

/// Reads `GET /attendance/records/summary/my` (§6.3): `present_days`,
/// `late_days`, `absent_days`, `total_work_hours`.
class AttendanceSummaryModel {
  const AttendanceSummaryModel._();

  static AttendanceSummary fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      presentDays: _int(json['present_days']) ?? 0,
      lateDays: _int(json['late_days']) ?? 0,
      absentDays: _int(json['absent_days']) ?? 0,
      totalWorkHours: _double(json['total_work_hours']) ?? 0,
    );
  }

  static int? _int(dynamic value) => (value as num?)?.toInt();

  static double? _double(dynamic value) => (value as num?)?.toDouble();
}
