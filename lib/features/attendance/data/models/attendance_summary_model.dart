import '../../domain/entities/attendance_summary.dart';

/// Reads `GET /attendance/records/summary/my`: every day count the server
/// keeps, and the hours worked. `total_overtime_hours` and the average
/// clock times are in the reply too and are not read here.
class AttendanceSummaryModel {
  const AttendanceSummaryModel._();

  static AttendanceSummary fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      totalWorkingDays: _int(json['total_working_days']) ?? 0,
      presentDays: _int(json['present_days']) ?? 0,
      lateDays: _int(json['late_days']) ?? 0,
      halfDays: _int(json['half_days']) ?? 0,
      incompleteDays: _int(json['incomplete_days']) ?? 0,
      absentDays: _int(json['absent_days']) ?? 0,
      leaveDays: _int(json['leave_days']) ?? 0,
      totalWorkHours: _double(json['total_work_hours']) ?? 0,
    );
  }

  static int? _int(dynamic value) => (value as num?)?.toInt();

  static double? _double(dynamic value) => (value as num?)?.toDouble();
}
