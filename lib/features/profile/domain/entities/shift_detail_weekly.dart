import 'package:equatable/equatable.dart';

/// A shift part's own times for one day of the week — from
/// `/core_hr/employees/me`'s `shift.shift_details[].weeklys[]`.
///
/// HR sets these when a weekday differs from the part's usual hours: a shop
/// that works 08:00–17:00 but closes at 12:00 on Saturday. A row only changes
/// the times; it never adds a part and never makes a day off.
class ShiftDetailWeekly extends Equatable {
  /// `MON` … `SUN`, as the backend sends it.
  final String weeklyDay;

  /// Raw `HH:mm[:ss]`, like the part's own times.
  final String? startTime;
  final String? endTime;

  /// That weekday's own allowances, when HR set them; null keeps the part's.
  final int? earlyCheckinMinutes;
  final int? lateCheckoutMinutes;

  const ShiftDetailWeekly({
    required this.weeklyDay,
    this.startTime,
    this.endTime,
    this.earlyCheckinMinutes,
    this.lateCheckoutMinutes,
  });

  @override
  List<Object?> get props => [
    weeklyDay,
    startTime,
    endTime,
    earlyCheckinMinutes,
    lateCheckoutMinutes,
  ];
}
