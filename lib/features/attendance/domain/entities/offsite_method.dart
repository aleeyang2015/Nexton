import 'attendance_day.dart';

/// Which punch an off-site scan request stands in for — §3's `method`.
///
/// Deliberately separate from [ClockMethod], which says *how* a punch proves
/// its location (`gps`/`wifi`/`field`). This says which *direction* the punch
/// goes, and the off-site endpoint is the only place the API asks for it.
enum OffsiteMethod {
  checkIn('check_in'),
  checkOut('check_out');

  const OffsiteMethod(this.wireValue);

  /// The literal the API expects in `method`.
  final String wireValue;

  /// The direction a request stands in for when it is filed to replace a punch
  /// that was refused for being out of area.
  ///
  /// Keeps the two vocabularies in one place: a scan filed after a rejected
  /// clock-in has to be a `check_in`, or the backend answers it against the
  /// wrong session and the employee is told they already clocked in.
  static OffsiteMethod forAction(ClockAction action) => switch (action) {
    ClockAction.clockIn => OffsiteMethod.checkIn,
    ClockAction.clockOut => OffsiteMethod.checkOut,
  };

  static OffsiteMethod? fromWire(String? value) {
    for (final method in OffsiteMethod.values) {
      if (method.wireValue == value) return method;
    }
    return null;
  }
}
