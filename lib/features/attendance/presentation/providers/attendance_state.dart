import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/attendance_day.dart';

part 'attendance_state.freezed.dart';

/// Everything the attendance card renders from.
@freezed
class AttendanceState with _$AttendanceState {
  const AttendanceState._();

  const factory AttendanceState({
    /// Today's record. Starts as data-with-empty rather than loading, so the
    /// card paints its "not checked in" resting state immediately instead of
    /// flashing a spinner on every cold start.
    @Default(AsyncValue.data(AttendanceDay.empty))
    AsyncValue<AttendanceDay> today,

    /// A punch is in flight. §7 rule 8 asks the client to suppress repeats
    /// itself rather than lean on the backend's session guard.
    @Default(false) bool isPunching,

    /// Set when the backend throttles a punch (429). Until it passes, the
    /// slide action is inert — §7 rule 10's cooldown.
    DateTime? cooldownUntil,
  }) = _AttendanceState;

  /// Today's record, or the empty day while it loads or after it failed.
  AttendanceDay get day => today.valueOrNull ?? AttendanceDay.empty;

  /// True while today's record is being fetched for the first time.
  bool get isLoadingToday => today.isLoading;

  /// True only when the open session actually belongs to today. A session
  /// left open across midnight by a forgotten clock-out no longer counts —
  /// otherwise the card would hang on "clock out" forever instead of letting
  /// the employee start the new day with a fresh clock-in.
  bool get isClockedIn {
    final clockIn = day.openSession?.clockIn;
    return clockIn != null && _isToday(clockIn);
  }

  /// Which endpoint the slide action should hit next.
  ClockAction get nextAction =>
      isClockedIn ? ClockAction.clockOut : ClockAction.clockIn;

  static bool _isToday(DateTime value) {
    final now = DateTime.now();
    return value.year == now.year &&
        value.month == now.month &&
        value.day == now.day;
  }

  bool get isCoolingDown {
    final until = cooldownUntil;
    return until != null && until.isAfter(DateTime.now());
  }

  /// The slide action is live only when nothing is in flight and no throttle
  /// is outstanding.
  bool get canPunch => !isPunching && !isCoolingDown;
}
