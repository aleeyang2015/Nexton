import 'package:equatable/equatable.dart';

import 'shift_detail_weekly.dart';

/// One segment of the employee's assigned shift — e.g. the morning half of a
/// split day — from `/core_hr/employees/me`'s `shift.shift_details[]`.
///
/// `startTime`/`endTime` arrive as the backend's raw `HH:mm[:ss]` strings,
/// not `DateTime`s: they describe a schedule, not a moment that happened.
class ShiftDetail extends Equatable {
  /// The segment's id — what a time-correction request sends as
  /// `shift_detail_id`.
  final String? id;
  final String? name;
  final String? nameLo;
  final String? startTime;
  final String? endTime;

  /// True for a part that runs past midnight (its end is not after its
  /// start), as the backend reports it.
  final bool endsNextDay;

  /// The weekdays whose times differ from [startTime]/[endTime], in the
  /// backend's order. Empty when every day keeps the part's own times.
  final List<ShiftDetailWeekly> weeklys;

  const ShiftDetail({
    this.id,
    this.name,
    this.nameLo,
    this.startTime,
    this.endTime,
    this.endsNextDay = false,
    this.weeklys = const [],
  });

  /// `weekly_day` codes by `DateTime.weekday` (1 = Monday … 7 = Sunday).
  static const List<String> _weekdayCodes = [
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
    'SUN',
  ];

  /// This part's times on [day]: the row for that weekday when HR set one,
  /// else the part's own.
  ///
  /// For a part that runs past midnight, [day] is the day it **starts**: a
  /// 22:00–06:00 shift begun on Monday keeps Monday's row at 02:00 on
  /// Tuesday. Callers pass the date of the record the times belong to, not
  /// necessarily today's.
  ({String? start, String? end}) timesOn(DateTime day) {
    final code = _weekdayCodes[day.weekday - 1];
    for (final row in weeklys) {
      if (row.weeklyDay.trim().toUpperCase() == code) {
        return (start: row.startTime, end: row.endTime);
      }
    }
    return (start: startTime, end: endTime);
  }

  @override
  List<Object?> get props => [
    id,
    name,
    nameLo,
    startTime,
    endTime,
    endsNextDay,
    weeklys,
  ];
}
