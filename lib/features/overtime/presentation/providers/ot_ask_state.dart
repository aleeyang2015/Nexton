import '../../../../core/errors/failure.dart';

/// The Ask OT form: what the user has picked and typed, and how sending
/// went.
class OtAskState {
  /// The day the OT starts, with no time.
  final DateTime workDate;

  /// `HH:MM`, null until picked.
  final String? startTime;
  final String? endTime;

  final String reason;

  /// True while the request is on its way.
  final bool sending;

  /// True when the server refused the End time (`422` on `end_time`: the
  /// end equals the start).
  final bool endError;

  /// Why the last send was refused (an `OtErrorCode` token, no employee
  /// record, no signal, a server error), for the page to say above Send.
  final Failure? refusal;

  /// Today, for the past-date warning.
  final DateTime today;

  const OtAskState({
    required this.workDate,
    required this.today,
    this.startTime,
    this.endTime,
    this.reason = '',
    this.sending = false,
    this.endError = false,
    this.refusal,
  });

  /// Both times picked, and not already sending.
  bool get canSend => startTime != null && endTime != null && !sending;

  /// An end at or before the start ends the next day (`22:00`–`02:00`), as
  /// the server reads it. An end equal to the start is not: the server
  /// refuses that.
  bool get endsNextDay {
    final start = startTime;
    final end = endTime;
    if (start == null || end == null) return false;
    return end.compareTo(start) < 0;
  }

  /// A day before today: the OT may pay little or nothing, as the time
  /// before approval could not be clocked as OT. A warning only.
  bool get isPastDate => workDate.isBefore(today);

  OtAskState copyWith({
    DateTime? workDate,
    String? startTime,
    String? endTime,
    String? reason,
    bool? sending,
    bool? endError,
    Failure? refusal,
    bool clearRefusal = false,
  }) => OtAskState(
    workDate: workDate ?? this.workDate,
    today: today,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    reason: reason ?? this.reason,
    sending: sending ?? this.sending,
    endError: endError ?? this.endError,
    refusal: clearRefusal ? null : (refusal ?? this.refusal),
  );
}
