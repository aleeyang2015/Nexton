/// How much of a day each requested date covers (leave-request-flutter.md §3.3).
///
/// A half-day request (`firstHalf`/`secondHalf`) must name exactly one date and
/// counts as `total_days = 0.5`.
enum LeaveDurationType {
  fullDay('full_day'),
  firstHalf('first_half'),
  secondHalf('second_half');

  const LeaveDurationType(this.wireValue);

  /// The string the API expects in the `duration_type` field.
  final String wireValue;

  bool get isHalfDay => this != LeaveDurationType.fullDay;

  static LeaveDurationType fromWire(String? value) {
    for (final type in LeaveDurationType.values) {
      if (type.wireValue == value) return type;
    }
    return LeaveDurationType.fullDay;
  }
}
