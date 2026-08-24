/// How a punch proves the employee was where they say they were (§1).
///
/// Each method obliges the client to supply different evidence, and the
/// backend rejects a punch whose evidence is missing — so the required
/// fields are declared here rather than re-derived at each call site.
enum ClockMethod {
  /// Geofence check against `latitude`/`longitude`.
  gps('gps'),

  /// Access-point check against `wifi_bssid`.
  wifi('wifi'),

  /// Off-site work; recorded immediately but held for a supervisor's
  /// approval, so it needs a written reason instead of a location.
  field('field');

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

  /// True when the punch cannot be sent without the AP's BSSID.
  bool get needsWifiBssid => this == ClockMethod.wifi;

  /// True when the punch cannot be sent without a typed reason.
  bool get needsFieldWorkReason => this == ClockMethod.field;
}
