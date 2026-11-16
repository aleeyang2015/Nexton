import 'package:equatable/equatable.dart';

/// `GET /attendance/records/summary/my` — the month's roll-up, as the server
/// counted it.
///
/// The server counts the days; the app never does. `records/my` has no row
/// for a day with no punch, so a count made on the phone would miss every
/// absent and leave day.
class AttendanceSummary extends Equatable {
  /// Days with a record, plus past work days with no scan: what the other
  /// counts are out of.
  final int totalWorkingDays;

  /// Present **or late** days: a late day is inside this number.
  final int presentDays;
  final int lateDays;
  final int halfDays;

  /// Days with a scan missing (a clock-in with no clock-out).
  final int incompleteDays;

  /// Past work days with no scan and no leave.
  final int absentDays;

  /// Days an approved leave covers.
  final int leaveDays;
  final double totalWorkHours;

  const AttendanceSummary({
    this.totalWorkingDays = 0,
    this.presentDays = 0,
    this.lateDays = 0,
    this.halfDays = 0,
    this.incompleteDays = 0,
    this.absentDays = 0,
    this.leaveDays = 0,
    this.totalWorkHours = 0,
  });

  static const empty = AttendanceSummary();

  @override
  List<Object?> get props => [
    totalWorkingDays,
    presentDays,
    lateDays,
    halfDays,
    incompleteDays,
    absentDays,
    leaveDays,
    totalWorkHours,
  ];
}
