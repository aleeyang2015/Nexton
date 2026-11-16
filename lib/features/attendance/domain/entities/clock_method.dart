/// How a punch proves the employee was where they say they were (§1).
///
/// The App punches by GPS only (owner decision): no Wi-Fi and no field punch.
/// The backend knows more methods, and old records still carry them
/// (`AttendanceCopy.methodLabel` names them in the history), but the phone
/// never sends them. Work away from every work area is an off-site request.
enum ClockMethod {
  /// Geofence check against `latitude`/`longitude`.
  gps('gps');

  const ClockMethod(this.wireValue);

  /// The literal the API expects in `method`.
  final String wireValue;

  static ClockMethod? fromWire(String? value) {
    for (final method in ClockMethod.values) {
      if (method.wireValue == value) return method;
    }
    return null;
  }

  /// True when the punch cannot be sent without device coordinates.
  bool get needsCoordinates => this == ClockMethod.gps;
}
