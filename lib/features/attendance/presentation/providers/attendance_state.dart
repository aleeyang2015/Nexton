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

  /// True while the record the card is about has an open session. That
  /// record is usually today's, but a night shift still running lives on
  /// yesterday's and a punch for a 00:00 shift on tomorrow's.
  ///
  /// Whether an open session still counts is decided once, where the record
  /// is chosen: [AttendanceDay.pickCurrent] never hands over a day shift left
  /// open by a forgotten clock-out, and does hand over a night shift that
  /// started yesterday. A second rule here ("opened today") would undo that:
  /// at 02:00 the night shift's card would offer clock-in.
  bool get isClockedIn => day.isClockedIn;

  /// Which endpoint the slide action should hit next.
  ClockAction get nextAction => day.nextAction;

  bool get isCoolingDown {
    final until = cooldownUntil;
    return until != null && until.isAfter(DateTime.now());
  }

  /// The slide action is live only when nothing is in flight and no throttle
  /// is outstanding.
  bool get canPunch => !isPunching && !isCoolingDown;
}
