/// What a time-correction request fixes — the four choices on the request
/// form's "ປະເພດການແກ້ໄຂ" card.
enum TimeCorrectionType {
  forgotClockIn,
  forgotClockOut,
  both,
  wrongTime;

  /// Whether the request carries a corrected clock-in time.
  bool get needsClockIn => this != TimeCorrectionType.forgotClockOut;

  /// Whether the request carries a corrected clock-out time.
  bool get needsClockOut => this != TimeCorrectionType.forgotClockIn;
}
