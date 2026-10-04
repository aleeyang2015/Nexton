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

  static OffsiteMethod? fromWire(String? value) {
    for (final method in OffsiteMethod.values) {
      if (method.wireValue == value) return method;
    }
    return null;
  }
}
