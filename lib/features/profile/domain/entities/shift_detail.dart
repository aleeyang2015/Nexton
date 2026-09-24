import 'package:equatable/equatable.dart';

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

  const ShiftDetail({
    this.id,
    this.name,
    this.nameLo,
    this.startTime,
    this.endTime,
  });

  @override
  List<Object?> get props => [id, name, nameLo, startTime, endTime];
}
