import 'package:equatable/equatable.dart';

/// `GET /attendance/records/summary/my` (§6.3) — the roll-up for a date
/// range, shown as the three stat cards atop the history page.
class AttendanceSummary extends Equatable {
  final int presentDays;
  final int lateDays;
  final int absentDays;
  final double totalWorkHours;

  const AttendanceSummary({
    this.presentDays = 0,
    this.lateDays = 0,
    this.absentDays = 0,
    this.totalWorkHours = 0,
  });

  static const empty = AttendanceSummary();

  @override
  List<Object?> get props => [presentDays, lateDays, absentDays, totalWorkHours];
}
