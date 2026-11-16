/// What a time-correction request fixes — the four choices on the request
/// form's "ປະເພດການແກ້ໄຂ" card.
enum TimeCorrectionType {
  forgotClockIn('missing_check_in'),
  forgotClockOut('missing_check_out'),
  both('both'),
  wrongTime('wrong_time');

  const TimeCorrectionType(this.wireValue);

  /// The literal the API expects in `correction_type`.
  final String wireValue;

  /// Whether the request carries a corrected clock-in time.
  bool get needsClockIn => this != TimeCorrectionType.forgotClockOut;

  /// Whether the request carries a corrected clock-out time.
  bool get needsClockOut => this != TimeCorrectionType.forgotClockIn;
}
